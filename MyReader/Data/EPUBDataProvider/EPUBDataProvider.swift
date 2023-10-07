//
//  EPUBDataProvider.swift
//  MyReader
//
//  Created by  Dennya on 18/09/2023.
//

import Foundation
import UIKit.UIColor

class EPUBDataProvider: Loggable {
    
    static let textColor = UIColor.black
    static let fontSize: CGFloat = 20
    
    typealias Content = EPUBContentDocumentParser.DocumentResult
    
    // MARK: - Nested Types
    
    struct UserTextSettings {
        let fontMultiplier: CGFloat
    }
    
    struct Result {
        let attributedString: NSAttributedString
        let images: [ImageInfo]
    }
    
    struct ImageInfo {
        let width: CGFloat
        let height: CGFloat
        let location: Int
        let url: URL
    }
    
    private struct Document {
        let url: URL
        let content: Content
    }
    
    private enum ImageSize {
        case ratio(CGFloat)
        case fixed(CSSNumericValue, CSSNumericValue)
    }
    
    private struct CoreTextRunInfo {
        let ascent: CGFloat
        let descent: CGFloat
        let width: CGFloat
    }
    
    // MARK: - Properties
    
    private let book: Book
    private let appManager: AppManager
    private let bookContentURL: URL
    private let baseBookURL: URL
    private let bookParseResult: EPUBParser.Result
    
    private let imagesCache = NSCache<NSURL, UIImage>()
    
    private var spineItems: [EPUBParser.SpineItem] {
        return bookParseResult.opfContainerParserResult.spineItems
    }
    private var manifestItems: [String: EPUBParser.ManifestItem] {
        return bookParseResult.opfContainerParserResult.manifestItems
    }
    
    private var documents: [Document] = []
    private var imageSizes: [URL: ImageSize] = [:]
    
    // MARK: - Init
    
    init?(appManager: AppManager, book: Book) {
        do {
            guard let bookId = book.bookId else {
                return nil
            }
            let bookContentUrl = try appManager.fileManager.getBookContentDirectory(bookId: bookId)
            let parseResult = try EPUBParser().parse(url: bookContentUrl)
            
            self.appManager = appManager
            self.book = book
            self.bookContentURL = bookContentUrl
            self.bookParseResult = parseResult
            
            let basePath = parseResult.xmlContainerParserResult.packageBasePath
            if basePath == "" {
                self.baseBookURL = self.bookContentURL
            } else {
                self.baseBookURL = self.bookContentURL.appendingPathComponent(basePath)
            }
        } catch {
            return nil
        }
    }
    
    // MARK: - Interface
    
    func bookContents(userTextSettings: UserTextSettings, pageSize: CGSize) -> [Result] {
        return parseBookContentIfNeeded().map({ mapDocumentToResult($0, userSettings: userTextSettings, pageSize: pageSize)})
    }
    
    func image(for url: URL) -> UIImage? {
        if let existing = imagesCache.object(forKey: url as NSURL) {
            return existing
        } else {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                imagesCache.setObject(image, forKey: url as NSURL)
                return image
            } else {
                print("No image with url \(url)")
                return nil
            }
        }
    }
    
    // MARK: - Logic
    
    private func parseBookContentIfNeeded() -> [Document] {
        guard documents.count == 0 else { return documents }
        
        let parser = EPUBContentDocumentParser()
        
        for spineItem in spineItems {
            if let manifest = manifestItems[spineItem.idref] {
                switch manifest.mediaType {
                case .htmlXml:
                    let url = baseBookURL.appendingPathComponent(manifest.href)
                    
                    guard let content = parser.parse(url: url) else { continue }
                    documents.append(.init(url: url, content: content))
                default:
                    break
                }
            }
        }
        return documents
    }
    
    private func mapDocumentToResult(_ document: Document, userSettings: UserTextSettings, pageSize: CGSize) -> Result {
        // TODO: Apply settings
        let resultString = NSMutableAttributedString()
        var images: [ImageInfo] = []
        
        for element in document.content.elements {
            switch element.elementType {
            case .text(let text):
                var attributes: [NSAttributedString.Key: Any] = [:]
                
                let fontInfo = element.attributes.font
                let size = Self.fontSize * fontInfo.sizeMultiplier
                let font = UIFont.systemFont(ofSize: size).with(traits: fontInfo.traits)
                
                attributes[.font] = font
                attributes[.foregroundColor] = element.attributes.textColor ?? Self.textColor
                attributes[.paragraphStyle] = paragraphStyle(for: element.attributes)
                resultString.append(NSAttributedString(string: text,attributes: attributes))
            case .image(let src):
                guard let imageUrl = getUrl(from: src, documentURL: document.url) else { continue }
                let imageSize = getImageSize(for: imageUrl, attributes: element.attributes)
                
                let width: CGFloat
                let height: CGFloat
                
                switch imageSize {
                case .ratio(let ratio):
                    let desiredHeight = pageSize.width / ratio
                    var scaleBy: CGFloat = 1
                    if desiredHeight > pageSize.height {
                        scaleBy = pageSize.height / desiredHeight
                    }
                    width = pageSize.width * scaleBy
                    height = desiredHeight * scaleBy
                case .fixed(let imageWidth, let imageHeight):
                    var scaleBy: CGFloat = 1
                    
                    let widthInPoints = imageWidth.pointSize(with: Self.fontSize)
                    let heightInPoints = imageHeight.pointSize(with: Self.fontSize)
                    
                    if widthInPoints > pageSize.width || heightInPoints > pageSize.height {
                        scaleBy = min(pageSize.width / widthInPoints, pageSize.height / heightInPoints)
                    }
                    
                    width = widthInPoints * scaleBy
                    height = heightInPoints
                }
                
                let extentBuffer = UnsafeMutablePointer<CoreTextRunInfo>.allocate(capacity: 1)
                extentBuffer.initialize(to: CoreTextRunInfo(ascent: height, descent: 0, width: width))
                var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
                }, getAscent: { (pointer) -> CGFloat in
                    let d = pointer.assumingMemoryBound(to: CoreTextRunInfo.self)
                    return d.pointee.ascent
                }, getDescent: { (pointer) -> CGFloat in
                    let d = pointer.assumingMemoryBound(to: CoreTextRunInfo.self)
                    return d.pointee.descent
                }, getWidth: { (pointer) -> CGFloat in
                    let d = pointer.assumingMemoryBound(to: CoreTextRunInfo.self)
                    return d.pointee.width
                })
                
                images.append(.init(width: width, height: height, location: resultString.length, url: imageUrl))
                
                let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
                let attributedString = NSAttributedString(string: "\u{FFFC}", attributes: [NSAttributedString.Key(kCTRunDelegateAttributeName as String): delegate as Any])
                resultString.append(attributedString)
            }
            
        }
        return .init(attributedString: resultString, images: images)
    }
    
    private func getImageSize(for url: URL, attributes: EPUBContentDocumentParser.DocumentResult.Element.Attributes) -> ImageSize {
        if let existing = imageSizes[url] {
            return existing
        }
        
        let imageSize: ImageSize
        if let width = attributes.width, let height = attributes.height {
            imageSize = .fixed(width, height)
        } else if let imageFileSize = ImageFileHelper.imageSize(from: url) {
            if let width = attributes.width {
                if imageFileSize.height != 0  {
                    let ratio = imageFileSize.width / imageFileSize.height
                    imageSize = .fixed(width, width / ratio)
                } else {
                    imageSize = .fixed(width, width)
                }
            } else if let height = attributes.height {
                if imageFileSize.height != 0 {
                    let ratio = imageFileSize.width / imageFileSize.height
                    imageSize = .fixed(height * ratio, height)
                } else {
                    imageSize = .fixed(height, height)
                }
            } else {
                if imageFileSize.height != 0 && imageFileSize.width != 0  {
                    imageSize = .ratio(imageFileSize.width / imageFileSize.height)
                } else {
                    imageSize = .ratio(1)
                }
            }
        } else {
            imageSize = .ratio(1)
        }
        imageSizes[url] = imageSize
        return imageSize
    }
    
    private func paragraphStyle(for attributes: EPUBContentDocumentParser.DocumentResult.Element.Attributes) -> NSParagraphStyle? {
        let ps = NSMutableParagraphStyle()
        ps.alignment = attributes.textAlign
        return ps
    }
    
    // MARK: - URLs
    
    private func getUrl(from href: String, documentURL: URL) -> URL? {
        let lowerPrefix = href.prefix(10).lowercased()
        if lowerPrefix.starts(with: "http://") || lowerPrefix.starts(with: "https://") {
            return URL(string: href)
        } else {
            return documentURL.deletingLastPathComponent().appendingPathComponent(href)
        }
    }
}
//
//extension EPUBDataProvider {
//    final class ImageSizeProvider {
//        
//        // MARK: - Interface
//        
//        func size(for element: EPUBContentDocumentParser.HTMLComponent.Element) -> CGSize? {
//            
//        }
//    }
//}

extension UIFont {
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}

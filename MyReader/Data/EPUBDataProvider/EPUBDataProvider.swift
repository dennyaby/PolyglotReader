//
//  EPUBDataProvider.swift
//  MyReader
//
//  Created by  Dennya on 18/09/2023.
//

import Foundation
import UIKit.UIColor
import UIKit

struct EPUBDataProviderConfig {
    let fontSize: CGFloat
    let textColor: UIColor
    
    static let standard = EPUBDataProviderConfig(fontSize: 20, textColor: .black)
}

struct EPUBDataProviderUserSettings {
    let fontMultiplier: CGFloat
}

struct EPUBDataProviderResult {
    let attributedString: NSAttributedString
    let images: [EPUBDataProvderImageInfo]
}

struct EPUBDataProvderImageInfo {
    let width: CGFloat
    let height: CGFloat
    let location: Int
    let url: URL
}

protocol EPUBDataProvider {
    
    init?(appManager: AppManager, book: Book, config: EPUBDataProviderConfig)
    
    func bookContents(userTextSettings: EPUBDataProviderUserSettings, pageSize: CGSize) -> [EPUBDataProviderResult]
    func image(for url: URL) -> UIImage?
}

class EPUBDataProviderAutoParse: Loggable, EPUBDataProvider {
    
    // MARK: - Properties
    
    private let config: EPUBDataProviderConfig
    private let appManager: AppManager
    private let book: Book
    private let bookContentURL: URL
    private let baseBookURL: URL
    private let bookParseResult: EPUBParser.Result
    
    private var spineItems: [EPUBParser.SpineItem] {
        return bookParseResult.opfContainerParserResult.spineItems
    }
    private var manifestItems: [String: EPUBParser.ManifestItem] {
        return bookParseResult.opfContainerParserResult.manifestItems
    }
    
    static let linksRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "<link[^>]*\\/>")
    }()
    
    static let hrefRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "href=\"([^\"]*)\"")
    }()
    
    static let typeRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "type=\"([^\"]*)\"")
    }()
    
    static let relRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "rel=\"([^\"]*)\"")
    }()
    
    // MARK: - Init
    
    required init?(appManager: AppManager, book: Book, config: EPUBDataProviderConfig = .standard) {
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
            self.config = config
        } catch {
            return nil
        }
    }
    
    // MARK: - Interface
    
    func bookContents(userTextSettings: EPUBDataProviderUserSettings, pageSize: CGSize) -> [EPUBDataProviderResult] {
        var strings: [NSAttributedString] = []
        var cssFiles: [URL: String] = [:]
        
        for spineItem in spineItems {
            if let manifest = manifestItems[spineItem.idref] {
                switch manifest.mediaType {
                case .htmlXml:
                    let url = baseBookURL.appendingPathComponent(manifest.href)
                    
                    do {
                        let data = try Data(contentsOf: url)
                        guard var string = String(data: data, encoding: .utf8) else { continue }
                        
                        if let linksRegExp = Self.linksRegExp, let relRegExp = Self.relRegExp, let typeRegExp = Self.typeRegExp, let hrefRegExp = Self.hrefRegExp {
                            
                            let range = NSRange(string.startIndex..<string.endIndex, in: string)
                            let matches = linksRegExp.matches(in: string, range: range)
                            let ranges = matches.compactMap { match in
                                return Range.init(match.range(at: 0), in: string)
                            }.reversed()
                            
                            for range in ranges {
                                let linkString = String(string[range])
                                let linkStringRange = NSRange(linkString.startIndex..<linkString.endIndex, in: linkString)
                                
                                if let relMatch = relRegExp.firstMatch(in: linkString, range: linkStringRange),
                                   relMatch.numberOfRanges >= 2,
                                   let relValueRange = Range(relMatch.range(at: 1), in: linkString),
                                   linkString[relValueRange] == "stylesheet" {
                                    if let typeMatch = typeRegExp.firstMatch(in: linkString, range: linkStringRange),
                                       typeMatch.numberOfRanges >= 2,
                                       let typeValueRange = Range(typeMatch.range(at: 1), in: linkString),
                                       linkString[typeValueRange] == "text/css" {
                                        if let hrefMatch = hrefRegExp.firstMatch(in: linkString, range: linkStringRange),
                                           hrefMatch.numberOfRanges >= 2,
                                           let hrefValueRange = Range(hrefMatch.range(at: 1), in: linkString) {
                                            let href = String(linkString[hrefValueRange])
                                            
                                            let cssFileUrl = url.deletingLastPathComponent().appendingPathComponent(href)
                                            
                                            var cssFile: String?
                                            if let existing = cssFiles[cssFileUrl] {
                                                cssFile = existing
                                            } else if let data = try? Data(contentsOf: cssFileUrl),
                                                      let cssString = String(data: data, encoding: .utf8){
                                                cssFile = cssString
                                                cssFiles[cssFileUrl] = cssString
                                            }
                                            
                                            if let cssFile = cssFile {
                                                string.replaceSubrange(range, with: "<style>\n\(cssFile)\n</style>")
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                        
                        guard let data = string.data(using: .utf8) else {
                            continue
                        }
                        
                        
                        let attributedString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                        strings.append(attributedString)
                    } catch {
                        print("Error constructing attributed string: \(error)")
                    }
                default:
                    break
                }
            }
        }
        return strings.map { .init(attributedString: $0, images: [])}
    }
    
    func image(for url: URL) -> UIImage? {
        return nil
    }
    
    // MARK: - Logic
}

class EPUBDataProviderManualParse: Loggable, EPUBDataProvider {
    
    typealias Content = EPUBContentDocumentParser.DocumentResult
    
    // MARK: - Nested Types
    
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
    
    private let config: EPUBDataProviderConfig
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
    
    required init?(appManager: AppManager, book: Book, config: EPUBDataProviderConfig = .standard) {
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
            self.config = config
        } catch {
            return nil
        }
    }
    
    // MARK: - Interface
    
    func bookContents(userTextSettings: EPUBDataProviderUserSettings, pageSize: CGSize) -> [EPUBDataProviderResult] {
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
    
    private func mapDocumentToResult(_ document: Document, userSettings: EPUBDataProviderUserSettings, pageSize: CGSize) -> EPUBDataProviderResult {
        // TODO: Apply settings
        let resultString = NSMutableAttributedString()
        var images: [EPUBDataProvderImageInfo] = []
        
        for element in document.content.elements {
            switch element.elementType {
            case .text(let text):
                var attributes: [NSAttributedString.Key: Any] = [:]
                
                let fontInfo = element.attributes.font
                let size = config.fontSize * fontInfo.sizeMultiplier
                let font = UIFont.systemFont(ofSize: size).with(traits: fontInfo.traits)
                
                attributes[.font] = font
                attributes[.foregroundColor] = element.attributes.textColor ?? config.textColor
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
                    
                    let widthInPoints = imageWidth.pointSize(with: config.fontSize)
                    let heightInPoints = imageHeight.pointSize(with: config.fontSize)
                    
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

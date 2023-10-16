//
//  EPUBDataProviderManualParse.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import Foundation
import UIKit.NSParagraphStyle
import UIKit.UIImage

class EPUBDataProviderManualParse: Loggable, EPUBDataProvider {
    
    typealias Content = EPUBContentDocumentParser.DocumentResult
    typealias Attributes = EPUBContentDocumentParser.DocumentResult.Element.Attributes
    
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
    
    private let fontManager = FontManager()
    private let paragraphStyleManager = ParagraphStyleManager()
    
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
                
                let font = fontManager.generateFont(for: element.attributes, pageSize: pageSize, config: config)
                let paragraphStyle = paragraphStyleManager.generateParagraphStyle(for: element.attributes, fontSize: font.fontSize, pageSize: pageSize, config: config)
                
                attributes[.font] = font.uiFont
                attributes[.foregroundColor] = element.attributes.color?.uiColor ?? config.textColor
                attributes[.paragraphStyle] = paragraphStyle
                resultString.append(NSAttributedString(string: text,attributes: attributes))
            case .image(let src):
                guard let imageUrl = getUrl(from: src, documentURL: document.url) else { continue }
                let logicalImageSize = getLogicalImageSize(for: imageUrl, attributes: element.attributes)
                let imageSize = getImageSize(forLogicalImageSize: logicalImageSize, toFitInside: pageSize)
                
                images.append(.init(width: imageSize.width, height: imageSize.height, location: resultString.length, url: imageUrl))
                resultString.append(attributedStringToReprentImage(withSize: imageSize))
            }
            
        }
        return .init(attributedString: resultString, images: images)
    }
    
    // MARK: - Image
    
    private func getLogicalImageSize(for url: URL, attributes: Attributes) -> ImageSize {
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
    
    private func getImageSize(forLogicalImageSize imageSize: ImageSize, toFitInside pageSize: CGSize) -> CGSize {
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
        return CGSize(width: width, height: height)
    }
    
    private func attributedStringToReprentImage(withSize imageSize: CGSize) -> NSAttributedString {
        let extentBuffer = UnsafeMutablePointer<CoreTextRunInfo>.allocate(capacity: 1)
        extentBuffer.initialize(to: CoreTextRunInfo(ascent: imageSize.height, descent: 0, width: imageSize.width))
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
        
        let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
        return NSAttributedString(string: "\u{FFFC}", attributes: [NSAttributedString.Key(kCTRunDelegateAttributeName as String): delegate as Any])
    }
    
    // MARK: - Common
    
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

extension EPUBDataProviderManualParse {
    final class FontManager {
        
        // MARK: - Nested Types
        
        struct Result {
            let fontSize: CGFloat
            let uiFont: UIFont
        }
        
        // MARK: - Interface
        
        func generateFont(for attributes: Attributes, pageSize: CGSize, config: EPUBDataProviderConfig) -> Result {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if let fontStyle = attributes.fontStyle, fontStyle.isItalic {
                traits.insert(.traitItalic)
            }
            
            var baseSize = config.fontSize
            if let fontSize = attributes.fontSize {
                switch fontSize {
                case .absolute(let absolute):
                    switch absolute {
                    case .xxSmall:
                        baseSize *= 0.3
                    case .xSmall:
                        baseSize *= 0.5
                    case .small:
                        baseSize *= 0.7
                    case .medium:
                        break
                    case .large:
                        baseSize *= 1.3
                    case .xLarge:
                        baseSize *= 1.7
                    case .xxLarge:
                        baseSize *= 2
                    case .xxxLarge:
                        baseSize *= 2.4
                    }
                case .relative(let relative):
                    switch relative {
                    case .larger:
                        baseSize *= 1.3
                    case .smaller:
                        baseSize *= 0.7
                    }
                case .numeric(let value):
                    baseSize = value.pointSize(with: baseSize)
                case .global(_):
                    break
                }
            }
            
            var weight: CGFloat = 400
            if let fontWeight = attributes.fontWeight {
                switch fontWeight {
                case .global(_):
                    break
                case .specific(let value):
                    weight = CGFloat(value)
                case .relative(let relative):
                    switch relative {
                    case .bolder:
                        weight *= 1.3
                    case .lighter:
                        weight *= 0.7
                    }
                }
            }
            // TODO: Solve problem with Weight
            
            let uiFont = UIFont.systemFont(ofSize: baseSize, weight: .init((weight - 400) / 400)).with(traits: traits)
            return .init(fontSize: baseSize, uiFont: uiFont)
        }
    }
}

extension EPUBDataProviderManualParse {
    final class ParagraphStyleManager {
        
        // MARK: - Interface
        
        func generateParagraphStyle(for attributes: Attributes, fontSize: CGFloat, pageSize: CGSize, config: EPUBDataProviderConfig) -> NSParagraphStyle {
            let ps = NSMutableParagraphStyle()
            ps.alignment = attributes.textAlign?.textAlign ?? .left
            
            ps.paragraphSpacingBefore = spacingsSum([attributes.paddingTop, attributes.marginTop], isHorizontal: false, fontSize: fontSize, pageSize: pageSize)
            ps.paragraphSpacing = spacingsSum([attributes.paddingBottom, attributes.marginBottom], isHorizontal: false, fontSize: fontSize, pageSize: pageSize)
            ps.tailIndent = -spacingsSum([attributes.paddingRight, attributes.marginRight], isHorizontal: true, fontSize: fontSize, pageSize: pageSize)
            
            let headIndent = spacingsSum([attributes.paddingLeft, attributes.marginLeft], isHorizontal: true, fontSize: fontSize, pageSize: pageSize)
            ps.firstLineHeadIndent = ps.firstLineHeadIndent + headIndent
            ps.headIndent = headIndent
            
            // TODO: I dont like that spacing between letters is different.
            
            return ps
        }
        
        // MARK: - Helper
        
        private func spacingsSum(_ spacings: [CSSNumericValue?], isHorizontal: Bool, fontSize: CGFloat, pageSize: CGSize) -> CGFloat {
            return spacings.compactMap({ $0 })
                .map({ numericValueToPoints($0, isHorizontal: isHorizontal, fontSize: fontSize, pageSize: pageSize)})
                .reduce(0, +)
        }
        
        private func numericValueToPoints(_ value: CSSNumericValue, isHorizontal: Bool, fontSize: CGFloat, pageSize: CGSize) -> CGFloat {
            switch value {
            case .pt(let pt): return pt
            case .px(let px): return px
            case .em(let em): return fontSize * em
            case .percent(let percent):
                let normalized = percent / 100
                return normalized * (isHorizontal ? pageSize.width : pageSize.height)
            }
        }
    }
}

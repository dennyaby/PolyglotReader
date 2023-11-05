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
        let fontFaces: [CSSParserResult.FontFace]
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
    
    func bookContents(config: EPUBDataProviderConfig, pageSize: CGSize) -> [EPUBDataProviderResult] {
        return parseBookContentIfNeeded().map({ mapDocumentToResult($0, config: config, pageSize: pageSize)})
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
                    documents.append(.init(url: url, content: content, fontFaces: content.fontFaces))
                default:
                    break
                }
            }
        }
        return documents
    }
    
    private func mapDocumentToResult(_ document: Document, config: EPUBDataProviderConfig, pageSize: CGSize) -> EPUBDataProviderResult {
        fontManager.startNewDocument(fontFaces: document.fontFaces, config: config)
        
        let resultString = NSMutableAttributedString()
        var images: [EPUBDataProvderImageInfo] = []
        
        for element in document.content.elements {
            switch element.elementType {
            case .text(let text):
                var attributes: [NSAttributedString.Key: Any] = [:]
                
                let font = fontManager.generateFont(for: element.attributes)
                let paragraphStyle = paragraphStyleManager.generateParagraphStyle(for: element.attributes, fontSize: font.fontSize, pageSize: pageSize, config: config)
                
                attributes[.font] = font.uiFont
                attributes[.foregroundColor] = element.attributes.color?.uiColor ?? config.textColor
                attributes[.paragraphStyle] = paragraphStyle
                resultString.append(NSAttributedString(string: text,attributes: attributes))
            case .image(let src):
                guard let imageUrl = URLResolver.resolveResource(path: src, linkedFrom: document.url) else { continue }
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
}

extension EPUBDataProviderManualParse {
    final class FontManager {
        /*
         Loop through all families. Set specific weight and italic/no italic. If not found - return system font. Eazy
         
         */
        
        static let baseFontSize: CGFloat = 16
        
        // MARK: - Nested Types
        
        struct Result {
            let fontSize: CGFloat
            let uiFont: UIFont
        }
        
        // MARK: - Properties
        
        private var config: EPUBDataProviderConfig?
        private var fontFaces: [CSSParserResult.FontFace] = []
        
        // MARK: - Interface
        
        func generateFont(for attributes: Attributes) -> Result {
            guard let config = config else {
                return .init(fontSize: Self.baseFontSize, uiFont: defaultFont(with: Self.baseFontSize))
            }
            
            var baseSize = config.fontSize
            if let fontSize = attributes.fontSize {
                switch fontSize {
                case .absolute(let absolute):
                    baseSize *= absolute.multiplier
                case .relative(_):
                    // TODO: It shouldn't be here. It should be handled upper the line
                    break
                case .numeric(let value):
                    baseSize = value.pointSize(with: baseSize)
                case .global(_):
                    break
                }
            }
            
            var weight: CGFloat?
            if let fontWeight = attributes.fontWeight {
                switch fontWeight {
                case .global(_):
                    break
                case .specific(let value):
                    weight = CGFloat(value)
                case .relative(_):
                    // TODO: It shouldn't be here. It should be handled upper the line
                    break
                }
            }
            
            let isItalic = attributes.fontStyle?.isItalic ?? false
            
            
            return .init(fontSize: baseSize, uiFont: font(for: attributes.fontFamily, baseSize: baseSize, weight: weight, isItalic: isItalic))
        }
        
        func startNewDocument(fontFaces: [CSSParserResult.FontFace], config: EPUBDataProviderConfig) {
            self.config = config
            self.fontFaces = fontFaces
            
            for fontFace in fontFaces {
                for source in fontFace.src {
                    do {
                        try FontRegisterManager.registerFontIfNeeded(url: source.url, by: fontFace.family.name())
                        print("Font has been registered")
                    } catch {
                        print("Error registering a font: \(error)")
                    }
                }
            }
        }
        
        // MARK: - Helper
        
        private func font(for family: CSSFontFamily?, baseSize: CGFloat, weight: CGFloat?, isItalic: Bool) -> UIFont {
            var fontWeight: UIFont.Weight = .regular
            
            var traits: [UIFontDescriptor.TraitKey: Any] = [:]
            if let weight = weight {
                fontWeight = UIFont.Weight(value: weight)
                traits[.weight] = fontWeight.rawValue
            }
            if isItalic {
                traits[.symbolic] = UIFontDescriptor.SymbolicTraits.traitItalic.rawValue
            }
            
            var font: UIFont?
            if let family = family {
                switch family {
                case .families(let families):
                    guard let family = families.first else { break }
                    
                    switch family {
                    case .specific(let familyName):
                        let realFamilyName = FontRegisterManager.getRealFamilyName(for: familyName)
                        let fontDescriptor = UIFontDescriptor().withFamily(realFamilyName).addingAttributes([.traits: traits])
                        
                        font = UIFont(descriptor: fontDescriptor, size: baseSize)
                    case .generic(let genericFamilyName):
                        switch genericFamilyName {
                        case .monospace, .uiMonospace:
                            font = UIFont.monospacedSystemFont(ofSize: baseSize, weight: fontWeight)
                        case .uiRounded:
                            if let fontDescriptor = UIFontDescriptor().withDesign(.rounded)?.addingAttributes([.traits: traits]) {
                                font = UIFont(descriptor: fontDescriptor, size: baseSize)
                            }
                        case .serif, .uiSerif:
                            if let fontDescriptor = UIFontDescriptor().withDesign(.serif)?.addingAttributes([.traits: traits]) {
                                font = UIFont(descriptor: fontDescriptor, size: baseSize)
                            }
                        case .emoji, .fangsong, .math, .systemUI, .sansSerif, .uiSanfSerif:
                            let fontDescriptor = UIFontDescriptor().addingAttributes([.traits: traits])
                            font = UIFont(descriptor: fontDescriptor, size: baseSize)
                        case .cursive:
                            let fontDescriptor = UIFontDescriptor().withFamily("Zapfino").addingAttributes([.traits: traits])
                            font = UIFont(descriptor: fontDescriptor, size: baseSize)
                        case .fantasy:
                            let fontDescriptor = UIFontDescriptor().withFamily("Party LET").addingAttributes([.traits: traits])
                            font = UIFont(descriptor: fontDescriptor, size: baseSize)
                        }
                    }
                default:
                    break
                }
            }
            if let font = font {
                return font
            } else {
                let fontDescriptor = UIFontDescriptor().addingAttributes([.traits: traits])
                return UIFont(descriptor: fontDescriptor, size: baseSize)
            }
        }
        
        private func defaultFont(with size: CGFloat) -> UIFont {
            return .systemFont(ofSize: size)
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
            
            // TODO: I dont like that spacing between letters is different. And there are no hypens -
            
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

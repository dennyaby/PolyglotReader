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
        let documentId: String
    }
    
    // MARK: - Properties
    
    private let config: EPUBDataProviderConfig
    private let book: Book
    private let appManager: AppManager
    private let bookContentURL: URL
    private let baseBookURL: URL
    private let bookParseResult: EPUBParser.Result
    
    private var spineItems: [EPUBParser.SpineItem] {
        return bookParseResult.opfContainerParserResult.spineItems
    }
    private var manifestItems: [String: EPUBParser.ManifestItem] {
        return bookParseResult.opfContainerParserResult.manifestItems
    }
    
    private var documents: [Document] = []
    
    private let fontManager = FontManager()
    private let paragraphStyleManager = ParagraphStyleManager()
    private let imageManager = ImageManager()
    
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
        return imageManager.image(for: url)
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
                    documents.append(.init(url: url, content: content, fontFaces: content.fontFaces, documentId: spineItem.idref))
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
                let logicalImageSize = imageManager.getLogicalImageSize(for: imageUrl, attributes: element.attributes)
                let imageSize = imageManager.getImageSize(forLogicalImageSize: logicalImageSize, toFitInside: pageSize, config: config)
                
                images.append(.init(width: imageSize.width, height: imageSize.height, location: resultString.length, url: imageUrl))
                
                let imageAttributedString = imageManager.attributedStringToReprentImage(withSize: imageSize)
                resultString.append(imageAttributedString)
            }
            
        }
        return .init(attributedString: resultString, documentId: document.documentId, images: images)
    }
}

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
    
    typealias Content = [EPUBContentDocumentParser.DocumentResult]
    
    // MARK: - Nested Types
    
    struct UserTextSettings {
        let fontMultiplier: CGFloat
    }
    
    // MARK: - Properties
    
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
    
    private var bookContent: Content = []
    
    // MARK: - Init
    
    init?(appManager: AppManager, book: Book) {
        do {
            guard let bookId = book.bookId else {
                return nil
            }
            let bookContentUrl = try appManager.fileManager.getBookContentDirectory(bookId: bookId)
            let start = Date()
            let parseResult = try EPUBParser().parse(url: bookContentUrl)
//            print("Time book parse = \(Date().timeIntervalSince(start))")
            
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
    
    func bookContents(userTextSettings: UserTextSettings) -> [NSAttributedString] {
        return apply(userSettings: userTextSettings, to: parseBookContentIfNeeded())
            .map(mapDocumentResultToAttributedString(_:))
    }
    
    // MARK: - Logic
    
    private func parseBookContentIfNeeded() -> Content {
        guard bookContent.count == 0 else { return bookContent }
        
        let parser = EPUBContentDocumentParser()
        
        for spineItem in spineItems {
            if let manifest = manifestItems[spineItem.idref] {
                switch manifest.mediaType {
                case .htmlXml:
                    let url = baseBookURL.appendingPathComponent(manifest.href)
                    
                    guard let content = parser.parse(url: url) else { continue }
                    bookContent.append(content)
                default:
                    break
                }
            }
        }
        return bookContent
    }
    
    private func apply(userSettings: UserTextSettings, to content: Content) -> Content {
        return content // TODO: Apply settings
    }
    
    private func mapDocumentResultToAttributedString(_ docResult: EPUBContentDocumentParser.DocumentResult) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for element in docResult.elements {
            var attributes: [NSAttributedString.Key: Any] = [:]
            
            let font: UIFont
            
            if let fontAttributes = element.attributes.font {
                let fontSize = Self.fontSize * fontAttributes.sizeMultiplier
                if fontAttributes.styles.contains(.italic) {
                    font = .italicSystemFont(ofSize: fontSize)
                } else if fontAttributes.styles.contains(.bold) {
                    font = .boldSystemFont(ofSize: fontSize)
                } else {
                    font = .systemFont(ofSize: fontSize)
                }
            } else {
                font = .systemFont(ofSize: Self.fontSize)
            }
            
            
            
            attributes[.font] = font
            attributes[.foregroundColor] = element.attributes.textColor ?? Self.textColor
            result.append(NSAttributedString(string: element.text,attributes: attributes))
        }
        return result
    }
}

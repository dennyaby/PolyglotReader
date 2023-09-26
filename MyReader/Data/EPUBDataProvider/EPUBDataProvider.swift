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
    
    private let imagesCache = NSCache<NSURL, UIImage>()
    
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
    
    func image(for url: URL) -> UIImage? {
        if let existing = imagesCache.object(forKey: url as NSURL) {
            return existing
        } else {
            if let image = UIImage(contentsOfFile: url.absoluteString) {
                imagesCache.setObject(image, forKey: url as NSURL)
                return image
            } else {
                print("No image with url \(url)")
                return nil
            }
        }
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
            switch element.elementType {
            case .text(let text):
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
                result.append(NSAttributedString(string: text,attributes: attributes))
            case .image(let src):
                guard let imageUrl = getUrl(from: src) else { continue }
                
//                Using ImageIO
//
//                NSURL *imageFileURL = [NSURL fileURLWithPath:...];
//                CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageFileURL, NULL);
//                if (imageSource == NULL) {
//                    // Error loading image
//                    ...
//                    return;
//                }
//
//                CGFloat width = 0.0f, height = 0.0f;
//                CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
//
//                CFRelease(imageSource);
//
//                if (imageProperties != NULL) {
//
//                    CFNumberRef widthNum  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
//                    if (widthNum != NULL) {
//                        CFNumberGetValue(widthNum, kCFNumberCGFloatType, &width);
//                    }
//
//                    CFNumberRef heightNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
//                    if (heightNum != NULL) {
//                        CFNumberGetValue(heightNum, kCFNumberCGFloatType, &height);
//                    }
//
//                    // Check orientation and flip size if required
//                    CFNumberRef orientationNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
//                    if (orientationNum != NULL) {
//                        int orientation;
//                        CFNumberGetValue(orientationNum, kCFNumberIntType, &orientation);
//                        if (orientation > 4) {
//                            CGFloat temp = width;
//                            width = height;
//                            height = temp;
//                        }
//                    }

                
                if let imageAttributes = element.attributes.image, let width = imageAttributes.width, let height = imageAttributes.heigth {
                    
                }
                
            }
            
        }
        return result
    }
    
    // MARK: - URLs
    
    private func getUrl(from href: String) -> URL? {
        let lowerPrefix = href.prefix(10).lowercased()
        if lowerPrefix.starts(with: "http://") || lowerPrefix.starts(with: "https://") {
            return URL(string: href)
        } else {
            return baseBookURL.appendingPathComponent(href)
        }
    }
}

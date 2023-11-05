//
//  EPUBDataProviderAutoParse.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import Foundation
import UIKit.UIImage

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
    
    func bookContents(config: EPUBDataProviderConfig, pageSize: CGSize) -> [EPUBDataProviderResult] {
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
                                            
                                            guard let cssFileUrl = URLResolver.resolveResource(path: href, linkedFrom: url) else { continue }
                                            
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

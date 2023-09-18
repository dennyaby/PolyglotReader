//
//  EPUBImportXMLContainerParser.swift
//  MyReader
//
//  Created by  Dennya on 12/09/2023.
//

import Foundation

extension EPUBParser {
    final class XMLContainerParser: NSObject, XMLParserDelegate {
        
        // MARK: - Nested Types
        
        struct Result {
            var rootFiles: [Rootfile]
            var packageBasePath = ""
            
            var opfFile: Rootfile? {
                return rootFiles.first(where: { $0.mediaType == .oebpsPackage })
            }
        }
        
        struct Rootfile {    
            let path: String
            let mediaType: MediaType
        }
        
        // MARK: - Properties
        
        private var result = Result(rootFiles: [])
        let url: URL
        
        // MARK: - Init
        
        init(url: URL) {
            self.url = url
            super.init()
        }
        
        // MARK: - Interface
        
        func parse() -> Result {
            guard let parser = XMLParser(contentsOf: url) else {
                return result
            }
            
            parser.delegate = self
            parser.parse()
            
            if let opfFile = result.opfFile {
                let pathComponents = opfFile.path.components(separatedBy: "/")
                if pathComponents.count > 1 {
                    result.packageBasePath = pathComponents.dropLast().joined(separator: "/").appending("/")
                }
            }
            
            return result
        }
        
        // MARK: - XMLParserDelegate
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "rootfile" {
                guard let fullPath = attributeDict["full-path"], let mediaType = attributeDict["media-type"] else {
                    return
                }
                
                result.rootFiles.append(.init(path: fullPath, mediaType: .init(from: mediaType)))
            }
        }
    }
}

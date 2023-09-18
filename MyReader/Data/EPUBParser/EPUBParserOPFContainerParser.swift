//
//  EPUBParserOPFContainerParser.swift
//  MyReader
//
//  Created by  Dennya on 13/09/2023.
//

import Foundation

extension EPUBParser {
    final class OPFContainerParser: NSObject, XMLParserDelegate {
        
        // MARK: - Nested Types
        
        struct Result {
            var titles: [String] = []
            var creator: String?
            var publisher: String?
            var subject: String?
            var languages: [String] = []
            var dateCreated: Date?
            var dateLastModified: Date?
            var epubLayout: EPUBLayout?
            var epubOrientation: EPUBOrientation?
            var epubSyntheticSpreads: EPUBSyntheticSpreads?
            var epubRenditionFlow: EPUBRenditionFlow?
            var manifestItems: [String: ManifestItem] = [:]
            var spineItems: [SpineItem] = []
            var metaItems: [MetaItem] = []
            var pageProgressionDirection: PageProgressionDirection?
        }
        
        // MARK: - Properties
        
        private var currentElement: String?
        private var currentElementAttributes: [String: String]?
        private var result = Result()
        let url: URL
        
        private var isManifestSection = false
        private var isSpineSection = false
        
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
            return result
        }
        
        // MARK: - XMLParserDelegate
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            currentElement = elementName
            currentElementAttributes = attributeDict
            
            switch elementName {
            case "manifest":
                isManifestSection = true
            case "item":
                if isManifestSection {
                    if let href = attributeDict["href"],
                       let id = attributeDict["id"],
                       let mediaType = attributeDict["media-type"] {
                        let manifestItem = ManifestItem(href: href,
                                                        id: id,
                                                        mediaType: .init(from: mediaType),
                                                        fallback: attributeDict["fallback"],
                                                        mediaOverlay: attributeDict["media-overlay"],
                                                        properties: .init(rawValue: attributeDict["properties"] ?? ""))
                        result.manifestItems[id] = manifestItem
                    }
                }
            case "spine":
                if let pageProgressionDirection = attributeDict["page-progression-direction"] {
                    result.pageProgressionDirection = .init(from: pageProgressionDirection)
                }
                isSpineSection = true
            case "itemref":
                if isSpineSection {
                    if let idref = attributeDict["idref"] {
                        let spineItem = SpineItem(id: attributeDict["id"],
                                                  idref: idref,
                                                  isLinear: (attributeDict["linear"] ?? "") != "no",
                                                  properties: .init(rawValue: attributeDict["properties"] ?? ""))
                        result.spineItems.append(spineItem)
                    }
                }
            case "meta":
                result.metaItems.append(.init(name: attributeDict["name"], content: attributeDict["content"], property: attributeDict["property"]))
            default:
                break
            }
        }
        
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            currentElement = nil
            currentElementAttributes = nil
            
            switch elementName {
            case "manifest":
                isManifestSection = false
            case "spine":
                isSpineSection = false
            default:
                break
            }
        }
        
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            guard let currentElement = currentElement else { return }
            
            switch currentElement {
            case "dc:title":
                result.titles.append(string)
            case "dc:creator":
                result.creator = string
            case "dc:language":
                result.languages.append(string)
            case "dc:date":
                result.dateCreated = DateFormatter.epubDefault.date(from: string)
            case "dc:publisher":
                result.publisher = string
            case "dc:subject":
                result.subject = string
            case "meta":
                if let propertyValue = currentElementAttributes?["property"] {
                    switch propertyValue {
                    case "dcterms:modified":
                        result.dateLastModified = DateFormatter.epubDefault.date(from: string)
                    case "rendition:layout":
                        result.epubLayout = .init(from: string)
                    case "rendition:orientation":
                        result.epubOrientation = .init(from: string)
                    case "rendition:spread":
                        result.epubSyntheticSpreads = .init(from: string)
                    case "rendition:flow":
                        result.epubRenditionFlow = .init(from: string)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
    }
}

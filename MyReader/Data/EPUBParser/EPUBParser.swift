//
//  EPUBParser.swift
//  MyReader
//
//  Created by  Dennya on 08/09/2023.
//

import Foundation

final class EPUBParser: NSObject, XMLParserDelegate {
    
    static let epubDocumentIdentifier = "org.idpf.epub-container"
    
    // MARK: - Nested Types
    
    enum Error: Swift.Error {
        case cannotLocateOpfFile
    }
    
    struct Result {
        let xmlContainerParserResult: XMLContainerParser.Result
        let opfContainerParserResult: OPFContainerParser.Result
    }
    
    // MARK: - Properties
    
    private let fm = FileManager.default
    
    // MARK: - Interface
    
    func parse(url: URL) throws -> Result {
        let contents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
        
        let metaInfFolder = url.appendingPathComponent("META-INF", isDirectory: true)
        let metaInfContents = try fm.contentsOfDirectory(at: metaInfFolder, includingPropertiesForKeys: nil)
        let containerXMLUrl = metaInfFolder.appendingPathComponent("container.xml")
        print(fm.fileExists(atPath: containerXMLUrl.standardizedFileURL.absoluteString))
        
        let xmlContainerParserResult = XMLContainerParser(url: containerXMLUrl).parse()
        
        guard let opfPackageRootFile = xmlContainerParserResult.rootFiles.first(where: { $0.mediaType == .oebpsPackage }) else {
            throw Error.cannotLocateOpfFile
        }
        
        let opfFileUrl = url.appendingPathComponent(opfPackageRootFile.path)
        let opfContainerParserResult = OPFContainerParser(url: opfFileUrl).parse()
        
        return Result(xmlContainerParserResult: xmlContainerParserResult, opfContainerParserResult: opfContainerParserResult)
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
        print("Did found attribute \(attributeName)")
    }
    
    func parser(_ parser: XMLParser, foundComment comment: String) {
        print("Found comment: \(comment)")
    }
    
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
        print("Found element declaration: \(elementName)")
    }
    
    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
        print("Did start mapping: \(prefix), namespace: \(namespaceURI)")
    }
    
    func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) {
        print("Did end mapping: \(prefix)")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("Did parsed")
    }
    
    func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
        print("foundProcessingInstruction")
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        print("Found data")
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print("Foudn characters")
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Error occured")
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("Validation error occured")
    }
    
    func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String) {
        print("Found ignorable whitespace")
    }
    
    func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? {
        print("Resolve external")
        return nil
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("Did end element")
    }
    
    func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
        print("Found internal ")
    }
    
    func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) {
        print("Found notation")
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

    }
}

extension EPUBParser {
    final class NavigationDocumentParser: NSObject, XMLParserDelegate {
        
        // MARK: - EmbededTypes
        
        enum NavigationListItemType {
            case title
            case link(String)
        }
        
        struct NavigationListItem {
            let text: String
            let itemType: NavigationListItemType
            
            let sublist: NavigationList?
        }
        
        struct NavigationList {
            let items: [NavigationListItem]
        }
        
        struct NavigationDocument {
            enum HeadingSize {
                case h1, h2, h3, h4, h5, h6
            }
            
            let headingText: String?
            let headingSize: HeadingSize?
            
            let list: NavigationList
        }
        
        // MARK: - Properties
        
        let url: URL
        
        // MARK: - Init
        
        init(url: URL) {
            self.url = url
            super.init()
        }
    }
}


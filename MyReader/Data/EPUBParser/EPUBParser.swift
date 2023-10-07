//
//  EPUBParser.swift
//  MyReader
//
//  Created by  Dennya on 08/09/2023.
//

import Foundation

final class EPUBParser: NSObject {
    
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
        let metaInfFolder = url.appendingPathComponent("META-INF", isDirectory: true)
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


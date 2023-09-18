//
//  EPUBDataProvider.swift
//  MyReader
//
//  Created by  Dennya on 18/09/2023.
//

import Foundation

class EPUBDataProvider: Loggable {
    
    static let port: UInt16 = 8080
    static let localhost = URL(string: "http://localhost:\(port)")!
    
    // MARK: - Properties
    
    private let book: Book
    private let server: WebServer
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
    
    var loadURLHandler: ((URL) -> ())?
    
    // MARK: - Init
    
    init?(appManager: AppManager, book: Book) {
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
            
            self.server = SimpleHTTPServer(port: Self.port)
        } catch {
            return nil
        }
        
        server.handleRequest { [weak self] request in
            return self?.handle(request: request) ?? .internalServerError
        }
    }
    
    // MARK: - Interface
    
    func start() {
        server.start()
        
        let spineItem = spineItems[0]
        if let manifestItem = manifestItems[spineItem.idref] {
            let url = Self.localhost.appendingPathComponent(manifestItem.href)
            log("Loading url: \(url)")
            loadURLHandler?(url)
        }
    }
    
    // MARK: - Requets
    
    private func handle(request: HTTPRequest) -> HTTPResponse {
        let fileUrl = baseBookURL.appendingPathComponent(request.fullPath.trimmingCharacters(in: .punctuationCharacters))
        
        do {
            let fileData = try Data(contentsOf: fileUrl)
            
            var contentType = "application/xhtml+xml"
            if let mediaType = manifestItems.values.first(where: { $0.href == request.fullPath })?.mediaType,
               case .unknown(let string) = mediaType {
                contentType = string
            }
            
            return HTTPResponse(status: .ok, headers: ["Content-Type": contentType], data: [UInt8](fileData))
        } catch {
            return HTTPResponse.internalServerError
        }
    }
    
    
    // TODO: Try to implement json return and try to read it correctly (it could be json file, it will be even better. And fix issues when server is not created when address is already in use

}

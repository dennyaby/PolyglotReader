//
//  WebServer.swift
//  MyReader
//
//  Created by  Dennya on 18/09/2023.
//

import Foundation

struct HTTPResponse {
    let status: HTTPStatus
    let headers: [String: String]
    let data: [UInt8]
    
    init(status: HTTPStatus, headers: [String : String], data: [UInt8]) {
        self.status = status
        self.data = data
        
        var headersCopy = headers
        if data.count > 0 {
            headersCopy["Content-Length"] = String(data.count)
        }
        headersCopy["Server"] = "MyReader"
        self.headers = headersCopy
    }
    
    static let notFound = HTTPResponse(status: .notFound, headers: [:], data: [])
    static let internalServerError = HTTPResponse(status: .internalServerError, headers: [:], data: [])
}

struct HTTPRequest {
    let method: String
    let fullPath: String
    let headers: [String: String]
    let body: Data?
}

struct HTTPStatus {
    let code: Int
    let reason: String
    
    static let ok = HTTPStatus(code: 200, reason: "OK")
    static let notFound = HTTPStatus(code: 404, reason: "Not Found")
    static let internalServerError = HTTPStatus(code: 500, reason: "Internal Server Error")
}

protocol WebServer {
    
    typealias RequestHandler = ((HTTPRequest) throws -> (HTTPResponse)) 
    
    var port: UInt16 { get }
    func handleRequest(with block: @escaping RequestHandler)
    
    @discardableResult
    func start() -> Bool
}

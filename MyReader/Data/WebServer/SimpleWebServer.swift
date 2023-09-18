//
//  SimpleWebServer.swift
//  MyReader
//
//  Created by  Dennya on 15/09/2023.
//

import Foundation

// Define a basic HTTP server class
class SimpleHTTPServer: WebServer, Loggable {
    
    // MARK: - Constants
    
    static let transportLayerProtocol = SOCK_STREAM // TCP
    static let internetLayerProtocol = AF_INET // IPv4
    static let maxNumberOfConnections: Int32 = 5
    static let errorCode: Int32 = -1
    
    // MARK: - Properties
    
    let port: UInt16
    let tcpSocket: Int32
    private var rootFolder: URL?
    private let fm = FileManager.default
    private var requestHandler: RequestHandler?
    
    private let queue = DispatchQueue.global(qos: .background)
    
    // MARK: - Init
    
    init(port: UInt16) {
        self.tcpSocket = socket(Self.internetLayerProtocol, Self.transportLayerProtocol, 0)
        self.port = port
        
        var iSetOption: Int = 1
        let socklen = socklen_t(UInt8(socklen_t(MemoryLayout<Int>.size)))
        let setOptions = withUnsafePointer(to: &iSetOption) { iSetOption in
            return setsockopt(tcpSocket, SOL_SOCKET, SO_REUSEADDR, iSetOption, socklen_t(MemoryLayout<Int>.size))
        }
        
        if setOptions == -1 {
            log("Error setting options: \(String(cString: strerror(errno)))")
        }
    }
    
    // MARK: - Interface
    
    @discardableResult
    func start() -> Bool {
        
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t((port << 8) + (port >> 8))
        address.sin_addr = in_addr(s_addr: in_addr_t(0))
        let zero = CChar(0)
        address.sin_zero = (zero, zero, zero, zero, zero, zero, zero, zero)
        
        var bindResult: Int32 = 0
        withUnsafePointer(to: &address) { sockadrinPtr in
            let sockadrPtr = UnsafeRawPointer(sockadrinPtr).assumingMemoryBound(to: sockaddr.self)
            let socklen = socklen_t(UInt8(socklen_t(MemoryLayout<sockaddr_in>.size)))
            bindResult = bind(tcpSocket, sockadrPtr, socklen)
        }
        
        if bindResult == Self.errorCode {
            log("Error binding socket: \(String(cString: strerror(errno)))")
            return false
        }
        
        if listen(tcpSocket, Self.maxNumberOfConnections) == Self.errorCode {
            log("Error listening a socket: \(String(cString: strerror(errno)))")
            return false
        }
        
        log("Server successfully started")
        self.queue.async { [weak self] in
            repeat {
                guard let socket = self?.tcpSocket else {
                    break
                }
                
                let client = accept(socket, nil, nil)
                
                guard let self = self else {
                    break
                }
                
                self.handleClient(socket: client)
            } while true
        }
        
        return true
    }
    
    func handleRequest(with block: @escaping RequestHandler) {
        self.requestHandler = block
    }
    
    // MARK: - Requests Handle
              
    
    private func handleClient(socket clientSocket: Int32) {
        guard let request = parseRequest(from: clientSocket) else {
            close(clientSocket)
            return
        }
        
        let response: HTTPResponse
        if let block = requestHandler {
            do {
                response = try block(request)
            } catch {
                response = .internalServerError
            }
        } else {
            response = .internalServerError
        }
        
        
        let raw = rawResponse(response: response)
        send(clientSocket, raw, raw.count, 0)
        close(clientSocket)
    }
    
    // MARK: - Logic
    
    private func rawResponse(response: HTTPResponse) -> [UInt8] {
        let string = (["HTTP/1.1 \(response.status.code) \(response.status.reason)"] + response.headers.map({ "\($0.key): \($0.value)"})).joined(separator: "\r\n") + "\r\n\r\n"
        return [UInt8](string.utf8) + response.data
    }
    
    private func parseRequest(from socket: Int32) -> HTTPRequest? {
        let bufferSize = 1024 // TODO: Handle bigger requests
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        let bytesRead = read(socket, &buffer, bufferSize)
        
        if bytesRead <= 0 {
            return nil
        }
        
        let bufferToUse = buffer.prefix(bytesRead)
        
        guard let requestString = String(bytes: bufferToUse, encoding: .utf8) else {
            return nil
        }
        
        log("Request length: \(requestString.count), buffer length: \(buffer.count), buffer to use length: \(bufferToUse.count)")
        
        
        let lines = requestString.components(separatedBy: .newlines)
        log("Lines: \(lines)")
        guard let requestLine = lines.first else {
            return nil
        }
        
        let requestLineItems = requestLine.components(separatedBy: .whitespaces)
        log("Request line items: \(requestLineItems)")
        guard requestLineItems.count >= 2 else {
            return nil
        }
        
        let method = String(requestLineItems[0])
        let path = String(requestLineItems[1])
        
        var headers: [String: String] = [:]
        
        let headerLines = lines.dropFirst()
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ $0.count > 0 })
        
        for line in headerLines {
            let parts = line
                .split(separator: ":", maxSplits: 1)
                .map({ String($0.trimmingCharacters(in: .whitespaces))})
            guard parts.count == 2 else { continue }
            headers[parts[0]] = parts[1]
        }
        
        var bodyData: Data?
        if let contentLengthHeader = headers["Content-Length"], let contentLength = Int(contentLengthHeader), contentLength > 0 {
            var data = Data(repeating: 0, count: contentLength)
            let startIndex = bytesRead - contentLength
            for index in 0..<contentLength {
                data[index] = buffer[startIndex + index]
            }
            bodyData = data
            
            log("Data count = \(data.count)")
            log(String(data: data, encoding: .utf8) ?? "No string")
        }
        
        return HTTPRequest(method: method, fullPath: path, headers: headers, body: bodyData)
    }
    
    // MARK: - Deinit
    
    deinit {
        close(tcpSocket)
    }
    
    
}



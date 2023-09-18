//
//  Log.swift
//  MyReader
//
//  Created by  Dennya on 16/09/2023.
//

import Foundation

protocol Loggable {
    var logIdentifier: String { get }
    func log(_ message: String)
}

extension Loggable where Self: AnyObject {
    var logIdentifier: String {
        return String(describing: self)
    }
}

extension Loggable {
    func log(_ message: String) {
        Log.log(message, logIdentifier: logIdentifier)
    }
}

struct Log {
    static var logSubjects: Set<String> = []
    
    static func log(_ message: String, logIdentifier: String) {
        if logSubjects.isEmpty || logSubjects.contains(logIdentifier) {
            print(message)
        }
    }
}

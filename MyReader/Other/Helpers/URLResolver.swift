//
//  URLResolver.swift
//  MyReader
//
//  Created by  Dennya on 01/11/2023.
//

import Foundation

final class URLResolver {
    
    static func resolveResource(path: String, linkedFrom url: URL) -> URL? {
        let lowerPrefix = path.prefix(10).lowercased()
        if lowerPrefix.starts(with: "http://") || lowerPrefix.starts(with: "https://") {
            return URL(string: path)
        }
        return url.deletingLastPathComponent().appendingPathComponent(path)
    }
}

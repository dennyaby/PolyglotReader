//
//  HTMLElement.swift
//  MyReader
//
//  Created by  Dennya on 05/10/2023.
//

import Foundation

enum HTMLElement: String, Hashable {
    case body
    case a
    case p
    case div
    case span
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
    case head
    case img
    case em
    case br
    case link
    case strong
    case b
    case cite
    case code
    case dfn
    case i
    case kbd
    case object
    case q
    case samp
    case sub
    case sup
    case time
    case variable = "var"
    case html
    case title
    case pre
    case unknown
    
    // MARK: - Init
    
    init(from: String) {
        let normalized = from.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let element = HTMLElement(rawValue: normalized) {
            self = element
        } else {
            self = .unknown
        }
    }
}

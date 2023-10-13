//
//  HTMLElement.swift
//  MyReader
//
//  Created by  Dennya on 05/10/2023.
//

import Foundation

enum HTMLElement: Hashable {
    case body
    case a
    case p
    case div
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
    case other(String)
    
    init(from: String) {
        switch from {
        case "body": self = .body
        case "a": self = .a
        case "div": self = .div
        case "p": self = .p
        case "h1": self = .h1
        case "h2": self = .h2
        case "h3": self = .h3
        case "h4": self = .h4
        case "h5": self = .h5
        case "h6": self = .h6
        case "head": self = .head
        case "img": self = .img
        case "em": self = .em
        case "br": self = .br
        case "link": self = .link
        default: self = .other(from)
        }
    }
}

//
//  HTMLElementType.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import Foundation

enum HTMLElementType {
    case textCss
    
    init?(from: String) {
        switch from {
        case "text/css":
            self = .textCss
        default:
            return nil
        }
    }
}

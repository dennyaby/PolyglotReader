//
//  CSSTextAlign.swift
//  MyReader
//
//  Created by  Dennya on 07/10/2023.
//

import UIKit

struct CSSTextAlign {
    
    // MARK: - Properties
    
    let textAlign: NSTextAlignment
    let string: String
    
    // MARK: - Init
    
    init?(from: String) {
        self.string = from
        let lowercased = from.lowercased()
        switch lowercased {
        case "start": textAlign = .left
        case "end": textAlign = .right
        case "center": textAlign = .center
        case "justify": textAlign = .justified
        default: return nil
        }
    }
}

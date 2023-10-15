//
//  CSSFontStyle.swift
//  MyReader
//
//  Created by  Dennya on 10/10/2023.
//

import Foundation

enum CSSFontStyle: Equatable {
    
    // MARK: - Nested Types
    
    enum Style: String, Equatable {
        case normal
        case italic
        case oblique
    }
    
    // MARK: - Enum
    
    case global(CSSGlobalValue)
    case style(Style)
    
    // MARK: - Init
    
    init?(string: String, useGlobalValue: Bool = true) {
        let normalized = string.components(separatedBy: " ")[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let style = Style(rawValue: normalized) {
            self = .style(style)
        } else if useGlobalValue, let global = CSSGlobalValue(rawValue: normalized) {
            self = .global(global)
        } else {
            return nil
        }
    }
}

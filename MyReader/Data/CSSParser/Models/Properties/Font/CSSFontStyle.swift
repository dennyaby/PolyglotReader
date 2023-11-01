//
//  CSSFontStyle.swift
//  MyReader
//
//  Created by  Dennya on 10/10/2023.
//

import Foundation

enum CSSFontStyle: Hashable {
    
    // MARK: - Nested Types
    
    enum Style: String, Hashable {
        case normal
        case italic
        case oblique
    }
    
    // MARK: - Enum
    
    case global(CSSGlobalValue)
    case style(Style)
    
    // MARK: - Computed properties
    
    var isItalic: Bool {
        switch self {
        case .global(_): return false
        case .style(let style): return style != .normal
        }
    }
    
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

//
//  CSSFontSize.swift
//  MyReader
//
//  Created by  Dennya on 11/10/2023.
//

import Foundation

enum CSSFontSize: Equatable {
    
    // MARK: - Nested Types
    
    enum Absolute: String, Equatable {
        case xxSmall = "xx-small"
        case xSmall = "x-small"
        case small
        case medium
        case large
        case xLarge = "x-large"
        case xxLarge = "xx-large"
        case xxxLarge = "xxx-large"
        
        var multiplier: CGFloat {
            switch self {
            case .xxSmall:
                return 0.3
            case .xSmall:
                return 0.5
            case .small:
                return 0.7
            case .medium:
                return 1
            case .large:
                return 1.3
            case .xLarge:
                return 1.7
            case .xxLarge:
                return 2
            case .xxxLarge:
                return 2.4
            }
        }
    }
    
    enum Relative: String, Equatable {
        case smaller
        case larger
    }
    
    // MARK: - Enum
    
    case absolute(Absolute)
    case relative(Relative)
    case numeric(CSSNumericValue)
    case global(CSSGlobalValue)
    
    // MARK: - Init
    
    init?(string: String, useGlobalValue: Bool = true) {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let absolute = Absolute(rawValue: normalized) {
            self = .absolute(absolute)
        } else if let relative = Relative(rawValue: normalized) {
            self = .relative(relative)
        } else if let numeric = CSSNumericValue(string: normalized) {
            self = .numeric(numeric)
        } else if useGlobalValue, let global = CSSGlobalValue(rawValue: normalized) {
            self = .global(global)
        } else {
            return nil   
        }
    }
}

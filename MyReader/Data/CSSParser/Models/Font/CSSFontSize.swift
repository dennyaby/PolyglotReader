//
//  CSSFontSize.swift
//  MyReader
//
//  Created by  Dennya on 11/10/2023.
//

import Foundation

// TODO: Create and test
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
    }
    
    enum Relative: String, Equatable {
        case smaller
        case larger
    }
    
    // MARK: - Enum
    
    case absolute(Absolute)
    case relative(Relative)
    case numeric(CSSNumericValue)
    case percent(CGFloat)
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
        } else {
            if normalized.firstIndex(of: "%") == normalized.index(before: normalized.endIndex),
               let percentValue = Double(normalized.dropLast(1)) {
                self = .percent(CGFloat(percentValue))
            } else if useGlobalValue, let global = CSSGlobalValue(rawValue: normalized) {
                self = .global(global)
            } else {
                return nil
            }
        }
    }
}

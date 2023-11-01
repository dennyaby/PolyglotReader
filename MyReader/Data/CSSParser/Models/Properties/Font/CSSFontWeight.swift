//
//  CSSFontWeight.swift
//  MyReader
//
//  Created by  Dennya on 10/10/2023.
//

import Foundation

enum CSSFontWeight: Equatable {
    
    static let normal = 400
    static let bold = 700
    
    // MARK: - Nested Types
    
    enum RelativeWeight: String, Equatable {
        case lighter
        case bolder
    }
    
    // MARK: - Enum
    
    case global(CSSGlobalValue)
    case specific(Int)
    case relative(RelativeWeight)
    
    // MARK: - Init
    
    init?(string: String, useGlobalValue: Bool = true) {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let relative = RelativeWeight(rawValue: normalized) {
            self = .relative(relative)
        } else {
            var boldness: Int?
            if normalized == "normal" {
                boldness = Self.normal
            } else if normalized == "bold" {
                boldness = Self.bold
            } else {
                boldness = Int(normalized)
            }
            
            if let boldness = boldness {
                self = .specific(max(1, min(1000, boldness)))
            } else {
                if useGlobalValue, let global = CSSGlobalValue(rawValue: normalized) {
                    self = .global(global)
                } else {
                    return nil
                }
            }
        }
    }
}

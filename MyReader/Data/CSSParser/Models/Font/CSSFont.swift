//
//  CSSFont.swift
//  MyReader
//
//  Created by  Dennya on 11/10/2023.
//

import Foundation

struct CSSFont {
    
    // MARK: - Static
    
    static let fontFamilyRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "([^\\s\"]+|\".+\")(?:[\\s]*,[\\s]*(?:[^\\s\",]+|\".+\")){1,}")
    }()
    
    // MARK: - Properties
    
    private(set) var fontFamily: CSSFontFamily?
    private(set) var fontStyle: CSSFontStyle?
    private(set) var fontWeight: CSSFontWeight?
    private(set) var fontSize: CSSFontSize?
    
    // MARK: - Init
    
    init(string: String) {
        var normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let multipleFontFamiles = Self.fontFamilyRegex?.firstMatch(in: normalized, range: NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)) {
            if let range = Range(multipleFontFamiles.range(at: 0), in: normalized) {
                fontFamily = CSSFontFamily(string: String(normalized[range]))
                
                normalized.removeSubrange(range)
            }
        }
        
        for component in normalized
            .components(separatedBy: " ")
            .filter({ $0.isEmpty == false }) {
            if let fontStyle = CSSFontStyle(string: component, useGlobalValue: false) {
                self.fontStyle = fontStyle
            } else if let fontWeight = CSSFontWeight(string: component, useGlobalValue: false) {
                self.fontWeight = fontWeight
            } else if let fontSize = CSSFontSize(string: component, useGlobalValue: false) {
                self.fontSize = fontSize
            } else if fontFamily == nil, let fontFamily = CSSFontFamily(string: component, useGlobalValue: false) {
                self.fontFamily = fontFamily
            }
        }
    }
}

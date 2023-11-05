//
//  CSSFontFamily.swift
//  MyReader
//
//  Created by  Dennya on 11/10/2023.
//

import Foundation

enum CSSFontFamily: Hashable {
    
    // MARK: - Nested Types
    
    enum GenericFontFamily: String, Hashable {
        case serif
        case sansSerif = "sans-serif"
        case monospace
        case cursive
        case fantasy
        case systemUI = "system-ui"
        case uiSerif = "ui-serif"
        case uiSanfSerif = "ui-sans-serif"
        case uiMonospace = "ui-monospace"
        case uiRounded = "ui-rounded"
        case emoji
        case math
        case fangsong
    }
    
    enum FontFamily: Hashable {
        case generic(GenericFontFamily)
        case specific(String)
    }
    
    // MARK: - Enum
    
    case global(CSSGlobalValue)
    case families([FontFamily])
    
    // MARK: - Init
    
    init?(string: String, useGlobalValue: Bool = true) {
        if let global = CSSGlobalValue(rawValue: string) {
            if useGlobalValue {
                self = .global(global)
            } else {
                return nil
            }
        } else {
            let families = string.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines ) }).compactMap { family in
                if let genericFamily = GenericFontFamily(rawValue: family) {
                    return FontFamily.generic(genericFamily)
                } else {
                    let familyString = family.replacingOccurrences(of: "\"", with: "")
                    if familyString.count > 0 {
                        return FontFamily.specific(familyString)
                    } else {
                        return nil
                    }
                }
            }
            
            if families.count > 0 {
                self = .families(families)
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Interface
    
    func name() -> String? {
        switch self {
        case .families(let families):
            guard let family = families.first else { return nil }
            switch family {
            case .generic(let family):
                return family.rawValue
            case .specific(let family):
                return family
            }
        default:
            return nil
        }
    }
}

//
//  CSSInsets.swift
//  MyReader
//
//  Created by  Dennya on 17/10/2023.
//

import Foundation

struct CSSInsets {
    
    // MARK: - Properties
    
    let top: CSSNumericValue?
    let bottom: CSSNumericValue?
    let left: CSSNumericValue?
    let right: CSSNumericValue?
    
    // MARK: - Init
    
    init?(from: String) {
        let normalized = from.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacingOccurrences(of: "auto", with: "0")
        let items = normalized.components(separatedBy: " ").filter({ $0 != "" })
        
        switch items.count {
        case 0:
            return nil
        case 1:
            guard let value = CSSNumericValue(string: items[0]) else {
                return nil // TODO: Here could be global values
            }
            top = value
            bottom = value
            left = value
            right = value
        case 2:
            guard let value1 = CSSNumericValue(string: items[0]),
                  let value2 = CSSNumericValue(string: items[1]) else {
                return nil
            }
            top = value1
            bottom = value1
            left = value2
            right = value2
        case 3:
            guard let value1 = CSSNumericValue(string: items[0]),
                  let value2 = CSSNumericValue(string: items[1]),
                  let value3 = CSSNumericValue(string: items[2]) else {
                return nil
            }
            
            top = value1
            left = value2
            right = value2
            bottom = value3
        case 4:
            guard let value1 = CSSNumericValue(string: items[0]),
                  let value2 = CSSNumericValue(string: items[1]),
                  let value3 = CSSNumericValue(string: items[2]),
                  let value4 = CSSNumericValue(string: items[3]) else {
                return nil
            }
            
            top = value1
            right = value2
            bottom = value3
            left = value4
        default:
            return nil;
        }
    }
    
}

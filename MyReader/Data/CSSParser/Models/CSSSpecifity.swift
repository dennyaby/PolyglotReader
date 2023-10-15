//
//  CSSSpecifity.swift
//  MyReader
//
//  Created by  Dennya on 15/10/2023.
//

import Foundation

struct CSSSpecifity: Hashable, Comparable {
    
    // MARK: - Properties
    
    let element: Int
    let classes: Int
    let id: Int
    
    // MARK: - Init
    
    init(element: HTMLElement?, classes: Set<String>, id: String?) {
        self.element = element == nil ? 0 : 1
        self.classes = classes.count
        self.id = id == nil ? 0 : 1
    }
    
    init(element: Int, classes: Int, id: Int) {
        self.element = element
        self.classes = classes
        self.id = id
    }
    
    // MARK: - Comparable
    
    static func < (lhs: CSSSpecifity, rhs: CSSSpecifity) -> Bool {
        guard lhs.id == rhs.id else {
            return lhs.id < rhs.id
        }
        guard lhs.classes == rhs.classes else {
            return lhs.classes < rhs.classes
        }
        return lhs.element < rhs.element
    }
    
    static func +(lhs: CSSSpecifity, rhs: CSSSpecifity) -> CSSSpecifity {
        return .init(element: lhs.element + rhs.element, classes: lhs.classes + rhs.classes, id: lhs.id + rhs.id)
    }
}

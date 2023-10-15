//
//  CSSEntity.swift
//  MyReader
//
//  Created by  Dennya on 15/10/2023.
//

import Foundation

struct CSSEntity: Hashable {
    
    // MARK: - Properties
    
    let element: HTMLElement?
    let classes: Set<String>
    let id: String?
    let specifity: CSSSpecifity
    
    // MARK: - Init
    
    init(element: HTMLElement? = nil, classes: Set<String> = [], id: String? = nil) {
        self.element = element
        self.classes = classes
        self.id = id
        self.specifity = CSSSpecifity(element: element, classes: classes, id: id)
    }
}

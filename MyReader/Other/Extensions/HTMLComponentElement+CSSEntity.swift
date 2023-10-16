//
//  HTMLComponentElement+CSSEntity.swift
//  MyReader
//
//  Created by  Dennya on 16/10/2023.
//

import Foundation

extension HTMLComponent.Element {
    var cssEntity: CSSEntity {
        let classes = Set((attributes["class"] ?? "").components(separatedBy: " ").filter({ $0.isEmpty == false }).map({ String($0) }))
        return CSSEntity(element: name, classes: classes, id: attributes["id"])
    }
}

//
//  CSSSelector.swift
//  MyReader
//
//  Created by  Dennya on 15/10/2023.
//

import Foundation

enum CSSSelector: Hashable {
    case all
    case entities([CSSEntity])
    case descendant(CSSEntity, CSSEntity)
    case child(CSSEntity, CSSEntity)
    case nextSibling(CSSEntity, CSSEntity)
    case subsequentSibling(CSSEntity, CSSEntity)
}

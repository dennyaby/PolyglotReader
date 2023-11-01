//
//  UIFontWeightFromHTMLWeight.swift
//  MyReader
//
//  Created by  Dennya on 20/10/2023.
//

import UIKit

extension UIFont.Weight {
    init(value: CGFloat) {
        switch value {
        case ...100:
            self = .thin
        case ...200:
            self = .ultraLight
        case ...300:
            self = .light
        case ...400:
            self = .regular
        case ...500:
            self = .medium
        case ...600:
            self = .semibold
        case ...700:
            self = .bold
        default:
            self = .black
        }
    }
}

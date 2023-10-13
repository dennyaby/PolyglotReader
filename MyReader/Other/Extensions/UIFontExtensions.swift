//
//  UIFontExtensions.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import UIKit.UIFont

extension UIFont {
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        
        return UIFont(descriptor: descriptor, size: 0)
    }
}

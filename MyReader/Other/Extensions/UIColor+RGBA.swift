//
//  Color.swift
//  MyReader
//
//  Created by  Dennya on 07/10/2023.
//

import UIKit.UIColor

extension UIColor {
    var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (r: r, g: g, b: b, a: a)
    }
    
    var hsla: (h: CGFloat, s: CGFloat, l: CGFloat, a: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var l: CGFloat = 0
        var a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &l, alpha: &a)
        
        return (h: h, s: s, l: l, a: a)
    }
}

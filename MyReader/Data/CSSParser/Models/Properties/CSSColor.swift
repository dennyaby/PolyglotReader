//
//  CSSColor.swift
//  MyReader
//
//  Created by  Dennya on 07/10/2023.
//

import Foundation
import UIKit.UIColor

struct CSSColor {
    
    // MARK: - Properties
    
    let string: String
    let uiColor: UIColor
    
    static let rgbRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "rgb\\(([\\d]{1,3})[ ]*,[ ]*([\\d]{1,3})[ ]*,[ ]*([\\d]{1,3})\\)")
    }()
    
    static let rgbaRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "rgba\\(([\\d]{1,3})[ ]*,[ ]*([\\d]{1,3})[ ]*,[ ]*([\\d]{1,3})[ ]*,[ ]*([\\d]+\\.[\\d]+|[\\d]+)\\)")
    }()
    
    static let hslRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "hsl\\(([\\d]+.[\\d]+|[\\d]+)[ ]*,[ ]*([\\d]{1,3})%[ ]*,[ ]*([\\d]{1,3})%[ ]*\\)")
    }()
    
    static let hslaRegExp: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "hsla\\(([\\d]+.[\\d]+|[\\d]+)[ ]*,[ ]*([\\d]{1,3})%[ ]*,[ ]*([\\d]{1,3})%[ ]*,[ ]*([\\d]+\\.[\\d]+|[\\d]+)\\)")
    }()
    
    // MARK: - Init
    
    init?(from: String) {
        self.string = from
        let lowercased = from.lowercased()
        if let namedColor = Self.colorNames[lowercased] {
            self.uiColor = namedColor
        } else {
            if let rgbColor = Self.fromRGB(input: lowercased) {
                self.uiColor = rgbColor
            } else if let rgbaColor = Self.fromRGBA(input: lowercased) {
                self.uiColor = rgbaColor
            } else if let hexColor = Self.fromHEX(input: lowercased) {
                self.uiColor = hexColor
            } else if let hslColor = Self.fromHSL(input: lowercased) {
                self.uiColor = hslColor
            } else if let hslaColor = Self.fromHSLA(input: lowercased) {
                self.uiColor = hslaColor
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Init Helpers
    
    private static func fromRGB(input: String) -> UIColor? {
        guard let regex = rgbRegExp else {
            return nil
        }
        
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let match = regex.firstMatch(in: input, range: range) else {
            return nil
        }
        
        guard match.numberOfRanges >= 4 else {
            return nil
        }
        
        guard let redStringRange = Range(match.range(at: 1), in: input),
              let greenStringRange = Range(match.range(at: 2), in: input),
              let blueStringRange = Range(match.range(at: 3), in: input) else {
            return nil
        }
        
        guard let red = Int(input[redStringRange]),
              let green = Int(input[greenStringRange]),
              let blue = Int(input[blueStringRange]) else {
            return nil
        }
        
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    private static func fromRGBA(input: String) -> UIColor? {
        guard let regex = rgbaRegExp else {
            return nil
        }
        
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let match = regex.firstMatch(in: input, range: range) else {
            return nil
        }
        
        guard match.numberOfRanges >= 5 else {
            return nil
        }
        
        guard let redStringRange = Range(match.range(at: 1), in: input),
              let greenStringRange = Range(match.range(at: 2), in: input),
              let blueStringRange = Range(match.range(at: 3), in: input),
              let alphaStringRange = Range(match.range(at: 4), in: input) else {
            return nil
        }
        
        guard let red = Int(input[redStringRange]),
              let green = Int(input[greenStringRange]),
              let blue = Int(input[blueStringRange]),
              let alpha = Double(input[alphaStringRange]) else {
            return nil
        }
        
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha))
    }
    
    private static func fromHEX(input: String) -> UIColor? {
        guard input.starts(with: "#") else {
            return nil
        }
        
        var hex = String(input.dropFirst())
        guard hex.count == 6 || hex.count == 3 else {
            return nil
        }
        
        if hex.count == 3 {
            var chars: [Character] = Array(hex)
            chars += chars
            chars[5] = chars[3]
            chars[4] = chars[3]
            chars[3] = chars[1]
            chars[2] = chars[1]
            chars[1] = chars[0]
            hex = String(chars)
        }
        
        var hexInt: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&hexInt) else {
            return nil
        }
        
        let red = CGFloat((hexInt & 0xFF0000) >> 16) / 255
        let green = CGFloat((hexInt & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hexInt & 0x0000FF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    private static func fromHSL(input: String) -> UIColor? {
        guard let regex = hslRegExp else {
            return nil
        }
        
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let match = regex.firstMatch(in: input, range: range) else {
            return nil
        }
        
        guard match.numberOfRanges >= 4 else {
            return nil
        }
        
        guard let hueStringRange = Range(match.range(at: 1), in: input),
              let saturationStringRange = Range(match.range(at: 2), in: input),
              let lightnessStringRange = Range(match.range(at: 3), in: input) else {
            return nil
        }
        
        guard let hue = Double(input[hueStringRange]),
              let saturation = Int(input[saturationStringRange]),
              let lightness = Int(input[lightnessStringRange]) else {
            return nil
        }
        
        return UIColor(hue: CGFloat(hue) / 360, saturation: CGFloat(saturation) / 100, brightness: CGFloat(lightness) / 100, alpha: 1)
    }
    
    private static func fromHSLA(input: String) -> UIColor? {
        guard let regex = hslaRegExp else {
            return nil
        }
        
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let match = regex.firstMatch(in: input, range: range) else {
            return nil
        }
        
        guard match.numberOfRanges >= 5 else {
            return nil
        }
        
        guard let hueStringRange = Range(match.range(at: 1), in: input),
              let saturationStringRange = Range(match.range(at: 2), in: input),
              let lightnessStringRange = Range(match.range(at: 3), in: input),
              let alphaStringRange = Range(match.range(at: 4), in: input) else {
            return nil
        }
        
        guard let hue = Double(input[hueStringRange]),
              let saturation = Int(input[saturationStringRange]),
              let lightness = Int(input[lightnessStringRange]),
              let alpha = Double(input[alphaStringRange]) else {
            return nil
        }
        
        return UIColor(hue: CGFloat(hue) / 360, saturation: CGFloat(saturation) / 100, brightness: CGFloat(lightness) / 100, alpha: CGFloat(alpha))
    }
}

extension CSSColor {
    static let colorNames: [String: UIColor] = [
        "aliceblue": UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1),
        "antiquewhite": UIColor(red: 0.98, green: 0.92, blue: 0.84, alpha: 1),
        "aqua": UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1),
        "aquamarine": UIColor(red: 0.5, green: 1.0, blue: 0.83, alpha: 1),
        "azure": UIColor(red: 0.94, green: 1.0, blue: 1.0, alpha: 1),
        "beige": UIColor(red: 0.96, green: 0.96, blue: 0.86, alpha: 1),
        "bisque": UIColor(red: 1.0, green: 0.89, blue: 0.77, alpha: 1),
        "black": UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1),
        "blanchedalmond": UIColor(red: 1.0, green: 0.92, blue: 0.8, alpha: 1),
        "blue": UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1),
        "blueviolet": UIColor(red: 0.54, green: 0.17, blue: 0.89, alpha: 1),
        "brown": UIColor(red: 0.65, green: 0.16, blue: 0.16, alpha: 1),
        "burlywood": UIColor(red: 0.87, green: 0.72, blue: 0.53, alpha: 1),
        "cadetblue": UIColor(red: 0.37, green: 0.62, blue: 0.63, alpha: 1),
        "chartreuse": UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1),
        "chocolate": UIColor(red: 0.82, green: 0.41, blue: 0.12, alpha: 1),
        "coral": UIColor(red: 1.0, green: 0.5, blue: 0.31, alpha: 1),
        "cornflowerblue": UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 1),
        "cornsilk": UIColor(red: 1.0, green: 0.97, blue: 0.86, alpha: 1),
        "crimson": UIColor(red: 0.86, green: 0.08, blue: 0.24, alpha: 1),
        "cyan": UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1),
        "darkblue": UIColor(red: 0.0, green: 0.0, blue: 0.55, alpha: 1),
        "darkcyan": UIColor(red: 0.0, green: 0.55, blue: 0.55, alpha: 1),
        "darkgoldenrod": UIColor(red: 0.72, green: 0.53, blue: 0.04, alpha: 1),
        "darkgray": UIColor(red: 0.66, green: 0.66, blue: 0.66, alpha: 1),
        "darkgrey": UIColor(red: 0.66, green: 0.66, blue: 0.66, alpha: 1),
        "darkgreen": UIColor(red: 0.0, green: 0.39, blue: 0.0, alpha: 1),
        "darkkhaki": UIColor(red: 0.74, green: 0.72, blue: 0.42, alpha: 1),
        "darkmagenta": UIColor(red: 0.55, green: 0.0, blue: 0.55, alpha: 1),
        "darkolivegreen": UIColor(red: 0.33, green: 0.42, blue: 0.18, alpha: 1),
        "darkorange": UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1),
        "darkorchid": UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1),
        "darkred": UIColor(red: 0.55, green: 0.0, blue: 0.0, alpha: 1),
        "darksalmon": UIColor(red: 0.91, green: 0.59, blue: 0.48, alpha: 1),
        "darkseagreen": UIColor(red: 0.56, green: 0.74, blue: 0.56, alpha: 1),
        "darkslateblue": UIColor(red: 0.28, green: 0.24, blue: 0.55, alpha: 1),
        "darkslategray": UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 1),
        "darkslategrey": UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 1),
        "darkturquoise": UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 1),
        "darkviolet": UIColor(red: 0.58, green: 0.0, blue: 0.83, alpha: 1),
        "deeppink": UIColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1),
        "deepskyblue": UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1),
        "dimgray": UIColor(red: 0.41, green: 0.41, blue: 0.41, alpha: 1),
        "dimgrey": UIColor(red: 0.41, green: 0.41, blue: 0.41, alpha: 1),
        "dodgerblue": UIColor(red: 0.12, green: 0.56, blue: 1.0, alpha: 1),
        "firebrick": UIColor(red: 0.7, green: 0.13, blue: 0.13, alpha: 1),
        "floralwhite": UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1),
        "forestgreen": UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1),
        "fuchsia": UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1),
        "gainsboro": UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1),
        "ghostwhite": UIColor(red: 0.97, green: 0.97, blue: 1.0, alpha: 1),
        "gold": UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1),
        "goldenrod": UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1),
        "gray": UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        "grey": UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        "green": UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1),
        "greenyellow": UIColor(red: 0.68, green: 1.0, blue: 0.18, alpha: 1),
        "honeydew": UIColor(red: 0.94, green: 1.0, blue: 0.94, alpha: 1),
        "hotpink": UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1),
        "indianred": UIColor(red: 0.8, green: 0.36, blue: 0.36, alpha: 1),
        "indigo": UIColor(red: 0.29, green: 0.0, blue: 0.51, alpha: 1),
        "ivory": UIColor(red: 1.0, green: 1.0, blue: 0.94, alpha: 1),
        "khaki": UIColor(red: 0.94, green: 0.9, blue: 0.55, alpha: 1),
        "lavender": UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1),
        "lavenderblush": UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1),
        "lawngreen": UIColor(red: 0.49, green: 0.99, blue: 0.0, alpha: 1),
        "lemonchiffon": UIColor(red: 1.0, green: 0.98, blue: 0.8, alpha: 1),
        "lightblue": UIColor(red: 0.68, green: 0.85, blue: 0.9, alpha: 1),
        "lightcoral": UIColor(red: 0.94, green: 0.5, blue: 0.5, alpha: 1),
        "lightcyan": UIColor(red: 0.88, green: 1.0, blue: 1.0, alpha: 1),
        "lightgoldenrodyellow": UIColor(red: 0.98, green: 0.98, blue: 0.82, alpha: 1),
        "lightgray": UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1),
        "lightgrey": UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1),
        "lightgreen": UIColor(red: 0.56, green: 0.93, blue: 0.56, alpha: 1),
        "lightpink": UIColor(red: 1.0, green: 0.71, blue: 0.76, alpha: 1),
        "lightsalmon": UIColor(red: 1.0, green: 0.63, blue: 0.48, alpha: 1),
        "lightseagreen": UIColor(red: 0.13, green: 0.7, blue: 0.67, alpha: 1),
        "lightskyblue": UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1),
        "lightslategray": UIColor(red: 0.47, green: 0.53, blue: 0.6, alpha: 1),
        "lightslategrey": UIColor(red: 0.47, green: 0.53, blue: 0.6, alpha: 1),
        "lightsteelblue": UIColor(red: 0.69, green: 0.77, blue: 0.87, alpha: 1),
        "lightyellow": UIColor(red: 1.0, green: 1.0, blue: 0.88, alpha: 1),
        "lime": UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1),
        "limegreen": UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1),
        "linen": UIColor(red: 0.98, green: 0.94, blue: 0.9, alpha: 1),
        "magenta": UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1),
        "maroon": UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1),
        "mediumaquamarine": UIColor(red: 0.4, green: 0.8, blue: 0.67, alpha: 1),
        "mediumblue": UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1),
        "mediumorchid": UIColor(red: 0.73, green: 0.33, blue: 0.83, alpha: 1),
        "mediumpurple": UIColor(red: 0.58, green: 0.44, blue: 0.86, alpha: 1),
        "mediumseagreen": UIColor(red: 0.24, green: 0.7, blue: 0.44, alpha: 1),
        "mediumslateblue": UIColor(red: 0.48, green: 0.41, blue: 0.93, alpha: 1),
        "mediumspringgreen": UIColor(red: 0.0, green: 0.98, blue: 0.6, alpha: 1),
        "mediumturquoise": UIColor(red: 0.28, green: 0.82, blue: 0.8, alpha: 1),
        "mediumvioletred": UIColor(red: 0.78, green: 0.08, blue: 0.52, alpha: 1),
        "midnightblue": UIColor(red: 0.1, green: 0.1, blue: 0.44, alpha: 1),
        "mintcream": UIColor(red: 0.96, green: 1.0, blue: 0.98, alpha: 1),
        "mistyrose": UIColor(red: 1.0, green: 0.89, blue: 0.88, alpha: 1),
        "moccasin": UIColor(red: 1.0, green: 0.89, blue: 0.71, alpha: 1),
        "navajowhite": UIColor(red: 1.0, green: 0.87, blue: 0.68, alpha: 1),
        "navy": UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1),
        "oldlace": UIColor(red: 0.99, green: 0.96, blue: 0.9, alpha: 1),
        "olive": UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1),
        "olivedrab": UIColor(red: 0.42, green: 0.56, blue: 0.14, alpha: 1),
        "orange": UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1),
        "orangered": UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1),
        "orchid": UIColor(red: 0.85, green: 0.44, blue: 0.84, alpha: 1),
        "palegoldenrod": UIColor(red: 0.93, green: 0.91, blue: 0.67, alpha: 1),
        "palegreen": UIColor(red: 0.6, green: 0.98, blue: 0.6, alpha: 1),
        "paleturquoise": UIColor(red: 0.69, green: 0.93, blue: 0.93, alpha: 1),
        "palevioletred": UIColor(red: 0.86, green: 0.44, blue: 0.58, alpha: 1),
        "papayawhip": UIColor(red: 1.0, green: 0.94, blue: 0.84, alpha: 1),
        "peachpuff": UIColor(red: 1.0, green: 0.85, blue: 0.73, alpha: 1),
        "peru": UIColor(red: 0.8, green: 0.52, blue: 0.25, alpha: 1),
        "pink": UIColor(red: 1.0, green: 0.75, blue: 0.8, alpha: 1),
        "plum": UIColor(red: 0.87, green: 0.63, blue: 0.87, alpha: 1),
        "powderblue": UIColor(red: 0.69, green: 0.88, blue: 0.9, alpha: 1),
        "purple": UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1),
        "rebeccapurple": UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1),
        "red": UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
        "rosybrown": UIColor(red: 0.74, green: 0.56, blue: 0.56, alpha: 1),
        "royalblue": UIColor(red: 0.25, green: 0.41, blue: 0.88, alpha: 1),
        "saddlebrown": UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1),
        "salmon": UIColor(red: 0.98, green: 0.5, blue: 0.45, alpha: 1),
        "sandybrown": UIColor(red: 0.96, green: 0.64, blue: 0.38, alpha: 1),
        "seagreen": UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1),
        "seashell": UIColor(red: 1.0, green: 0.96, blue: 0.93, alpha: 1),
        "sienna": UIColor(red: 0.63, green: 0.32, blue: 0.18, alpha: 1),
        "silver": UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1),
        "skyblue": UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1),
        "slateblue": UIColor(red: 0.42, green: 0.35, blue: 0.8, alpha: 1),
        "slategray": UIColor(red: 0.44, green: 0.5, blue: 0.56, alpha: 1),
        "slategrey": UIColor(red: 0.44, green: 0.5, blue: 0.56, alpha: 1),
        "snow": UIColor(red: 1.0, green: 0.98, blue: 0.98, alpha: 1),
        "springgreen": UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1),
        "steelblue": UIColor(red: 0.27, green: 0.51, blue: 0.71, alpha: 1),
        "tan": UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1),
        "teal": UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1),
        "thistle": UIColor(red: 0.85, green: 0.75, blue: 0.85, alpha: 1),
        "tomato": UIColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1),
        "turquoise": UIColor(red: 0.25, green: 0.88, blue: 0.82, alpha: 1),
        "violet": UIColor(red: 0.93, green: 0.51, blue: 0.93, alpha: 1),
        "wheat": UIColor(red: 0.96, green: 0.87, blue: 0.7, alpha: 1),
        "white": UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
        "whitesmoke": UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1),
        "yellow": UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1),
        "yellowgreen": UIColor(red: 0.6, green: 0.8, blue: 0.2, alpha: 1)
    ]
}

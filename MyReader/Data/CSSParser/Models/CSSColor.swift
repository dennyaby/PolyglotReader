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
        if let namedColor = Self.colorNames[from] {
            self.uiColor = namedColor
        } else {
            let lowercased = from.lowercased()
            
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
        "AliceBlue" : UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1),
        "AntiqueWhite" : UIColor(red: 0.98, green: 0.92, blue: 0.84, alpha: 1),
        "Aqua" : UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1),
        "Aquamarine" : UIColor(red: 0.5, green: 1.0, blue: 0.83, alpha: 1),
        "Azure" : UIColor(red: 0.94, green: 1.0, blue: 1.0, alpha: 1),
        "Beige" : UIColor(red: 0.96, green: 0.96, blue: 0.86, alpha: 1),
        "Bisque" : UIColor(red: 1.0, green: 0.89, blue: 0.77, alpha: 1),
        "Black" : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1),
        "BlanchedAlmond" : UIColor(red: 1.0, green: 0.92, blue: 0.8, alpha: 1),
        "Blue" : UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1),
        "BlueViolet" : UIColor(red: 0.54, green: 0.17, blue: 0.89, alpha: 1),
        "Brown" : UIColor(red: 0.65, green: 0.16, blue: 0.16, alpha: 1),
        "BurlyWood" : UIColor(red: 0.87, green: 0.72, blue: 0.53, alpha: 1),
        "CadetBlue" : UIColor(red: 0.37, green: 0.62, blue: 0.63, alpha: 1),
        "Chartreuse" : UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1),
        "Chocolate" : UIColor(red: 0.82, green: 0.41, blue: 0.12, alpha: 1),
        "Coral" : UIColor(red: 1.0, green: 0.5, blue: 0.31, alpha: 1),
        "CornflowerBlue" : UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 1),
        "Cornsilk" : UIColor(red: 1.0, green: 0.97, blue: 0.86, alpha: 1),
        "Crimson" : UIColor(red: 0.86, green: 0.08, blue: 0.24, alpha: 1),
        "Cyan" : UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1),
        "DarkBlue" : UIColor(red: 0.0, green: 0.0, blue: 0.55, alpha: 1),
        "DarkCyan" : UIColor(red: 0.0, green: 0.55, blue: 0.55, alpha: 1),
        "DarkGoldenRod" : UIColor(red: 0.72, green: 0.53, blue: 0.04, alpha: 1),
        "DarkGray" : UIColor(red: 0.66, green: 0.66, blue: 0.66, alpha: 1),
        "DarkGrey" : UIColor(red: 0.66, green: 0.66, blue: 0.66, alpha: 1),
        "DarkGreen" : UIColor(red: 0.0, green: 0.39, blue: 0.0, alpha: 1),
        "DarkKhaki" : UIColor(red: 0.74, green: 0.72, blue: 0.42, alpha: 1),
        "DarkMagenta" : UIColor(red: 0.55, green: 0.0, blue: 0.55, alpha: 1),
        "DarkOliveGreen" : UIColor(red: 0.33, green: 0.42, blue: 0.18, alpha: 1),
        "DarkOrange" : UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1),
        "DarkOrchid" : UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1),
        "DarkRed" : UIColor(red: 0.55, green: 0.0, blue: 0.0, alpha: 1),
        "DarkSalmon" : UIColor(red: 0.91, green: 0.59, blue: 0.48, alpha: 1),
        "DarkSeaGreen" : UIColor(red: 0.56, green: 0.74, blue: 0.56, alpha: 1),
        "DarkSlateBlue" : UIColor(red: 0.28, green: 0.24, blue: 0.55, alpha: 1),
        "DarkSlateGray" : UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 1),
        "DarkSlateGrey" : UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 1),
        "DarkTurquoise" : UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 1),
        "DarkViolet" : UIColor(red: 0.58, green: 0.0, blue: 0.83, alpha: 1),
        "DeepPink" : UIColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1),
        "DeepSkyBlue" : UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1),
        "DimGray" : UIColor(red: 0.41, green: 0.41, blue: 0.41, alpha: 1),
        "DimGrey" : UIColor(red: 0.41, green: 0.41, blue: 0.41, alpha: 1),
        "DodgerBlue" : UIColor(red: 0.12, green: 0.56, blue: 1.0, alpha: 1),
        "FireBrick" : UIColor(red: 0.7, green: 0.13, blue: 0.13, alpha: 1),
        "FloralWhite" : UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1),
        "ForestGreen" : UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1),
        "Fuchsia" : UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1),
        "Gainsboro" : UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1),
        "GhostWhite" : UIColor(red: 0.97, green: 0.97, blue: 1.0, alpha: 1),
        "Gold" : UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1),
        "GoldenRod" : UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1),
        "Gray" : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        "Grey" : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        "Green" : UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1),
        "GreenYellow" : UIColor(red: 0.68, green: 1.0, blue: 0.18, alpha: 1),
        "HoneyDew" : UIColor(red: 0.94, green: 1.0, blue: 0.94, alpha: 1),
        "HotPink" : UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1),
        "IndianRed" : UIColor(red: 0.8, green: 0.36, blue: 0.36, alpha: 1),
        "Indigo" : UIColor(red: 0.29, green: 0.0, blue: 0.51, alpha: 1),
        "Ivory" : UIColor(red: 1.0, green: 1.0, blue: 0.94, alpha: 1),
        "Khaki" : UIColor(red: 0.94, green: 0.9, blue: 0.55, alpha: 1),
        "Lavender" : UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1),
        "LavenderBlush" : UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1),
        "LawnGreen" : UIColor(red: 0.49, green: 0.99, blue: 0.0, alpha: 1),
        "LemonChiffon" : UIColor(red: 1.0, green: 0.98, blue: 0.8, alpha: 1),
        "LightBlue" : UIColor(red: 0.68, green: 0.85, blue: 0.9, alpha: 1),
        "LightCoral" : UIColor(red: 0.94, green: 0.5, blue: 0.5, alpha: 1),
        "LightCyan" : UIColor(red: 0.88, green: 1.0, blue: 1.0, alpha: 1),
        "LightGoldenRodYellow" : UIColor(red: 0.98, green: 0.98, blue: 0.82, alpha: 1),
        "LightGray" : UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1),
        "LightGrey" : UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1),
        "LightGreen" : UIColor(red: 0.56, green: 0.93, blue: 0.56, alpha: 1),
        "LightPink" : UIColor(red: 1.0, green: 0.71, blue: 0.76, alpha: 1),
        "LightSalmon" : UIColor(red: 1.0, green: 0.63, blue: 0.48, alpha: 1),
        "LightSeaGreen" : UIColor(red: 0.13, green: 0.7, blue: 0.67, alpha: 1),
        "LightSkyBlue" : UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1),
        "LightSlateGray" : UIColor(red: 0.47, green: 0.53, blue: 0.6, alpha: 1),
        "LightSlateGrey" : UIColor(red: 0.47, green: 0.53, blue: 0.6, alpha: 1),
        "LightSteelBlue" : UIColor(red: 0.69, green: 0.77, blue: 0.87, alpha: 1),
        "LightYellow" : UIColor(red: 1.0, green: 1.0, blue: 0.88, alpha: 1),
        "Lime" : UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1),
        "LimeGreen" : UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1),
        "Linen" : UIColor(red: 0.98, green: 0.94, blue: 0.9, alpha: 1),
        "Magenta" : UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1),
        "Maroon" : UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1),
        "MediumAquaMarine" : UIColor(red: 0.4, green: 0.8, blue: 0.67, alpha: 1),
        "MediumBlue" : UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1),
        "MediumOrchid" : UIColor(red: 0.73, green: 0.33, blue: 0.83, alpha: 1),
        "MediumPurple" : UIColor(red: 0.58, green: 0.44, blue: 0.86, alpha: 1),
        "MediumSeaGreen" : UIColor(red: 0.24, green: 0.7, blue: 0.44, alpha: 1),
        "MediumSlateBlue" : UIColor(red: 0.48, green: 0.41, blue: 0.93, alpha: 1),
        "MediumSpringGreen" : UIColor(red: 0.0, green: 0.98, blue: 0.6, alpha: 1),
        "MediumTurquoise" : UIColor(red: 0.28, green: 0.82, blue: 0.8, alpha: 1),
        "MediumVioletRed" : UIColor(red: 0.78, green: 0.08, blue: 0.52, alpha: 1),
        "MidnightBlue" : UIColor(red: 0.1, green: 0.1, blue: 0.44, alpha: 1),
        "MintCream" : UIColor(red: 0.96, green: 1.0, blue: 0.98, alpha: 1),
        "MistyRose" : UIColor(red: 1.0, green: 0.89, blue: 0.88, alpha: 1),
        "Moccasin" : UIColor(red: 1.0, green: 0.89, blue: 0.71, alpha: 1),
        "NavajoWhite" : UIColor(red: 1.0, green: 0.87, blue: 0.68, alpha: 1),
        "Navy" : UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1),
        "OldLace" : UIColor(red: 0.99, green: 0.96, blue: 0.9, alpha: 1),
        "Olive" : UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1),
        "OliveDrab" : UIColor(red: 0.42, green: 0.56, blue: 0.14, alpha: 1),
        "Orange" : UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1),
        "OrangeRed" : UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1),
        "Orchid" : UIColor(red: 0.85, green: 0.44, blue: 0.84, alpha: 1),
        "PaleGoldenRod" : UIColor(red: 0.93, green: 0.91, blue: 0.67, alpha: 1),
        "PaleGreen" : UIColor(red: 0.6, green: 0.98, blue: 0.6, alpha: 1),
        "PaleTurquoise" : UIColor(red: 0.69, green: 0.93, blue: 0.93, alpha: 1),
        "PaleVioletRed" : UIColor(red: 0.86, green: 0.44, blue: 0.58, alpha: 1),
        "PapayaWhip" : UIColor(red: 1.0, green: 0.94, blue: 0.84, alpha: 1),
        "PeachPuff" : UIColor(red: 1.0, green: 0.85, blue: 0.73, alpha: 1),
        "Peru" : UIColor(red: 0.8, green: 0.52, blue: 0.25, alpha: 1),
        "Pink" : UIColor(red: 1.0, green: 0.75, blue: 0.8, alpha: 1),
        "Plum" : UIColor(red: 0.87, green: 0.63, blue: 0.87, alpha: 1),
        "PowderBlue" : UIColor(red: 0.69, green: 0.88, blue: 0.9, alpha: 1),
        "Purple" : UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1),
        "RebeccaPurple" : UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1),
        "Red" : UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
        "RosyBrown" : UIColor(red: 0.74, green: 0.56, blue: 0.56, alpha: 1),
        "RoyalBlue" : UIColor(red: 0.25, green: 0.41, blue: 0.88, alpha: 1),
        "SaddleBrown" : UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1),
        "Salmon" : UIColor(red: 0.98, green: 0.5, blue: 0.45, alpha: 1),
        "SandyBrown" : UIColor(red: 0.96, green: 0.64, blue: 0.38, alpha: 1),
        "SeaGreen" : UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1),
        "SeaShell" : UIColor(red: 1.0, green: 0.96, blue: 0.93, alpha: 1),
        "Sienna" : UIColor(red: 0.63, green: 0.32, blue: 0.18, alpha: 1),
        "Silver" : UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1),
        "SkyBlue" : UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1),
        "SlateBlue" : UIColor(red: 0.42, green: 0.35, blue: 0.8, alpha: 1),
        "SlateGray" : UIColor(red: 0.44, green: 0.5, blue: 0.56, alpha: 1),
        "SlateGrey" : UIColor(red: 0.44, green: 0.5, blue: 0.56, alpha: 1),
        "Snow" : UIColor(red: 1.0, green: 0.98, blue: 0.98, alpha: 1),
        "SpringGreen" : UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1),
        "SteelBlue" : UIColor(red: 0.27, green: 0.51, blue: 0.71, alpha: 1),
        "Tan" : UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1),
        "Teal" : UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1),
        "Thistle" : UIColor(red: 0.85, green: 0.75, blue: 0.85, alpha: 1),
        "Tomato" : UIColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1),
        "Turquoise" : UIColor(red: 0.25, green: 0.88, blue: 0.82, alpha: 1),
        "Violet" : UIColor(red: 0.93, green: 0.51, blue: 0.93, alpha: 1),
        "Wheat" : UIColor(red: 0.96, green: 0.87, blue: 0.7, alpha: 1),
        "White" : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
        "WhiteSmoke" : UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1),
        "Yellow" : UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1),
        "YellowGreen" : UIColor(red: 0.6, green: 0.8, blue: 0.2, alpha: 1)
    ]
}

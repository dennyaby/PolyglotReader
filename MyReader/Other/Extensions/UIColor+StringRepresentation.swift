//
//  UIColor+StringRepresentation.swift
//  MyReader
//
//  Created by  Dennya on 06/11/2023.
//

import UIKit.UIColor

extension UIColor {
    
    // MARK: - Constants
    
    private static let colorFormat = "color(%f, %f, %f, %f)"
    
    // MARK: - Init
    
    convenience init?(stringRepresentation: String) {
        let lowercased = stringRepresentation.lowercased()
        
        let components = lowercased
            .replacingOccurrences(of: "color(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .components(separatedBy: ",")
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines )})
        
        guard components.count == 4 else { return nil }
        
        let red = CGFloat((components[0] as NSString).doubleValue)
        let green = CGFloat((components[1] as NSString).doubleValue)
        let blue = CGFloat((components[2] as NSString).doubleValue)
        let alpha = CGFloat((components[3] as NSString).doubleValue)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: - Interface
    
    func stringRepresentation() -> String {
        let (r, g, b, a) = self.rgba
        return String(format: Self.colorFormat, r, g, b, a)
    }
    
}

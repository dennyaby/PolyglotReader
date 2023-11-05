//
//  FontRegisterManager.swift
//  MyReader
//
//  Created by  Dennya on 31/10/2023.
//

import CoreText
import UIKit.UIFont

// TODO: Why static? Create instance
final class FontRegisterManager {
    
    // MARK: - Nested Types
    
    enum RegisterError: Error {
        case cannotLoadFontFromURL
        case cannotConstructFontData
        case cannotRegisterFont(String)
    }
    
    // MARK: - No instances
    
    private init() {}
    
    // MARK: - Properties
    
    private static var registeredCache: Set<URL> = []
    private static var registeredFontsFamilyMap: [String: String] = [:]
    
    // MARK: - Interface
    
    static func registerFontIfNeeded(url: URL, by family: String? = nil) throws {
        guard registeredCache.contains(url) == false else { return }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw RegisterError.cannotLoadFontFromURL
        }
        
        try registerFont(data: data, by: family)
        registeredCache.insert(url)
    }
    
    static func registerFont(data: Data, by family: String? = nil) throws {
        guard let provider = CGDataProvider(data: data as CFData) else { throw RegisterError.cannotConstructFontData }
        
        guard let font = CGFont(provider) else { throw RegisterError.cannotConstructFontData }
        
        var error: Unmanaged<CFError>?
        
        if CTFontManagerRegisterGraphicsFont(font, &error) == false {
            throw RegisterError.cannotRegisterFont(error.debugDescription)
        }
        
        guard let byFamily = family else { return }
        guard let fontFullName = font.fullName else { return }
        
        guard let uiFont = UIFont(name: fontFullName as String, size: 15) else { return }
        
        let realFamilyName = uiFont.familyName
        if realFamilyName != byFamily {
            self.registeredFontsFamilyMap[byFamily] = realFamilyName
        }
    }
    
    static func getRealFamilyName(for family: String) -> String {
        if let mappedValue = self.registeredFontsFamilyMap[family] {
            return mappedValue
        }
        return family
    }
    
}

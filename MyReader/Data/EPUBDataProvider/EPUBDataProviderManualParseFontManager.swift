//
//  EPUBDataProviderManualParseFontManager.swift
//  MyReader
//
//  Created by  Dennya on 05/11/2023.
//

import Foundation
import UIKit.UIFont

extension EPUBDataProviderManualParse {
    final class FontManager {
        /*
         Loop through all families. Set specific weight and italic/no italic. If not found - return system font. Eazy
         
         */
        
        static let baseFontSize: CGFloat = 16
        
        // MARK: - Nested Types
        
        struct Result {
            let fontSize: CGFloat
            let uiFont: UIFont
        }
        
        // MARK: - Properties
        
        private var config: EPUBDataProviderConfig?
        private var fontFaces: [CSSParserResult.FontFace] = []
        
        // MARK: - Interface
        
        func generateFont(for attributes: Attributes) -> Result {
            guard let config = config else {
                return .init(fontSize: Self.baseFontSize, uiFont: defaultFont(with: Self.baseFontSize))
            }
            
            var baseSize = config.fontSize
            if let fontSize = attributes.fontSize {
                switch fontSize {
                case .absolute(let absolute):
                    baseSize *= absolute.multiplier
                case .relative(_):
                    // TODO: It shouldn't be here. It should be handled upper the line
                    break
                case .numeric(let value):
                    baseSize = value.pointSize(with: baseSize)
                case .global(_):
                    break
                }
            }
            
            var weight: CGFloat?
            if let fontWeight = attributes.fontWeight {
                switch fontWeight {
                case .global(_):
                    break
                case .specific(let value):
                    weight = CGFloat(value)
                case .relative(_):
                    // TODO: It shouldn't be here. It should be handled upper the line
                    break
                }
            }
            
            let isItalic = attributes.fontStyle?.isItalic ?? false
            
            
            return .init(fontSize: baseSize, uiFont: font(for: attributes.fontFamily, baseSize: baseSize, weight: weight, isItalic: isItalic))
        }
        
        func startNewDocument(fontFaces: [CSSParserResult.FontFace], config: EPUBDataProviderConfig) {
            self.config = config
            self.fontFaces = fontFaces
            
            for fontFace in fontFaces {
                for source in fontFace.src {
                    do {
                        try FontRegisterManager.registerFontIfNeeded(url: source.url, by: fontFace.family.name())
                    } catch {
                        print("Error registering a font: \(error)")
                    }
                }
            }
        }
        
        // MARK: - Helper
        
        private func font(for family: CSSFontFamily?, baseSize: CGFloat, weight: CGFloat?, isItalic: Bool) -> UIFont {
            var fontWeight: UIFont.Weight = .regular
            
            var traits: [UIFontDescriptor.TraitKey: Any] = [:]
            if let weight = weight {
                fontWeight = UIFont.Weight(value: weight)
                traits[.weight] = fontWeight.rawValue
            }
            if isItalic {
                traits[.symbolic] = UIFontDescriptor.SymbolicTraits.traitItalic.rawValue
            }
            
            var font: UIFont?
            if let family = family {
                switch family {
                case .families(let families):
                    guard let family = families.first else { break }
                    
                    switch family {
                    case .specific(let familyName):
                        let realFamilyName = FontRegisterManager.getRealFamilyName(for: familyName)
                        let fontDescriptor = UIFontDescriptor().withFamily(realFamilyName).addingAttributes([.traits: traits])
                        
                        font = UIFont(descriptor: fontDescriptor, size: baseSize)
                    case .generic(let genericFamilyName):
                        switch genericFamilyName {
                        case .monospace, .uiMonospace:
                            font = UIFont.monospacedSystemFont(ofSize: baseSize, weight: fontWeight)
                        case .uiRounded:
                            if let fontDescriptor = UIFontDescriptor().withDesign(.rounded)?.addingAttributes([.traits: traits]) {
                                font = UIFont(descriptor: fontDescriptor, size: baseSize)
                            }
                        case .serif, .uiSerif:
                            if let fontDescriptor = UIFontDescriptor().withDesign(.serif)?.addingAttributes([.traits: traits]) {
                                font = UIFont(descriptor: fontDescriptor, size: baseSize)
                            }
                        case .emoji, .fangsong, .math, .systemUI, .sansSerif, .uiSanfSerif:
                            let fontDescriptor = UIFontDescriptor().addingAttributes([.traits: traits])
                            font = UIFont(descriptor: fontDescriptor, size: baseSize)
                        case .cursive:
                            let fontDescriptor = UIFontDescriptor().withFamily("Zapfino").addingAttributes([.traits: traits])
                            font = UIFont(descriptor: fontDescriptor, size: baseSize)
                        case .fantasy:
                            let fontDescriptor = UIFontDescriptor().withFamily("Party LET").addingAttributes([.traits: traits])
                            font = UIFont(descriptor: fontDescriptor, size: baseSize)
                        }
                    }
                default:
                    break
                }
            }
            if let font = font {
                return font
            } else {
                let fontDescriptor = UIFontDescriptor().addingAttributes([.traits: traits])
                return UIFont(descriptor: fontDescriptor, size: baseSize)
            }
        }
        
        private func defaultFont(with size: CGFloat) -> UIFont {
            return .systemFont(ofSize: size)
        }
    }
}

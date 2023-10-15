//
//  EPUBContentDocumentParserResult.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import UIKit

extension EPUBContentDocumentParser {
    struct DocumentResult {
        struct Element {
            enum ElementType {
                case text(String)
                case image(String)
            }
            
            var elementType: ElementType
            let attributes: Attributes
            
            // MARK: - Attributes
            
            struct Attributes {
                
                // TODO: Remove inner structs
                // TODO: Is all attributes should live more then one element?
                
                var fontTraits: UIFontDescriptor.SymbolicTraits = []
                var fontSize: CSSNumericValue?
                struct Font {
                    var traits: UIFontDescriptor.SymbolicTraits
                    var sizeMultiplier: CGFloat
                    
                    init(traits: UIFontDescriptor.SymbolicTraits = [], sizeMultiplier: CGFloat = 1) {
                        self.traits = traits
                        self.sizeMultiplier = sizeMultiplier
                    }
                }
                
                struct Image {
                    var alt: String?
                }
                
                var textColor: UIColor?
                var font = Font()
                var image = Image()
                var href: String?
                var src: String?
                var alt: String?
                var display: CSSDisplay?
                var width: CSSNumericValue?
                var height: CSSNumericValue?
                var textAlign: NSTextAlignment?
            }
        }
        
        let elements: [Element]
    }
}

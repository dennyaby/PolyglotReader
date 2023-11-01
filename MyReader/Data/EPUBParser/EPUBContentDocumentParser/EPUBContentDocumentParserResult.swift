//
//  EPUBContentDocumentParserResult.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import UIKit

extension EPUBContentDocumentParser {
    struct DocumentResult {
        
        // MARK: - Nested Types
        
        struct Element {
            enum ElementType {
                case text(String)
                case image(String)
            }
            
            var elementType: ElementType
            let attributes: Attributes
            
            // MARK: - Attributes
            
            struct Attributes {
                
                // TODO: Is all attributes should live more then one element?
                
                // General
                
                var color: CSSColor?
                var display: CSSDisplay?
                var width: CSSNumericValue?
                var height: CSSNumericValue?
                
                // Font & Text
                
                var fontSize: CSSFontSize?
                var fontWeight: CSSFontWeight?
                var fontFamily: CSSFontFamily?
                var fontStyle: CSSFontStyle?
                var textAlign: CSSTextAlign?
                
                // Spacings
                
                var marginTop: CSSNumericValue?
                var marginBottom: CSSNumericValue?
                var marginLeft: CSSNumericValue?
                var marginRight: CSSNumericValue?
                
                var paddingTop: CSSNumericValue?
                var paddingBottom: CSSNumericValue?
                var paddingLeft: CSSNumericValue?
                var paddingRight: CSSNumericValue?
                
                // Other
                
                var href: String?
                var src: String?
                var alt: String?
            }
        }
        
        // MARK: - Properties
        
        let elements: [Element]
        let fontFaces: [CSSParserResult.FontFace]
    }
}

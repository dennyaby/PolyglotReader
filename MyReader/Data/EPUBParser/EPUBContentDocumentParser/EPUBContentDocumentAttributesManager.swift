//
//  EPUBContentDocumentAttributesManager.swift
//  MyReader
//
//  Created by  Dennya on 17/10/2023.
//

import Foundation

extension EPUBContentDocumentParser {
    final class AttributesManager {
        
        typealias Attributes = DocumentResult.Element.Attributes
        
        // MARK: - Interface
        
        func apply(htmlAttributes: [String: String], css: CSSParserResult?, to element: HTMLComponent.Element, ancestors: [CSSEntity], previousSiblings: [CSSEntity], currentAttributes: Attributes) -> Attributes {
            var result = currentAttributes
            if let css = css {
                result = apply(css: css, to: element, ancestors: ancestors, previousSiblings: previousSiblings, currentAttributes: result)
            }
            
            result = apply(htmlAttributes: htmlAttributes, to: result)
            
            return result
        }
        
        // MARK: - HTML Attributes
        
        private func apply(htmlAttributes: [String: String], to attributes: Attributes) -> Attributes {
            var result = attributes
            
            if let width = htmlAttributes["width"], let widthValue = CSSNumericValue(string: width) {
                result.width = widthValue
            }
            
            if let height = htmlAttributes["height"], let heightValue = CSSNumericValue(string: height) {
                result.height = heightValue
            }
            
            if let href = htmlAttributes["href"] {
                result.href = href
            }
            
            if let alt = htmlAttributes["alt"] {
                result.alt = alt
            }
            
            if let src = htmlAttributes["src"] {
                result.src = src
            }
            
            return result
        }
        
        // MARK: - CSS Attributes
        
        private func apply(css: CSSParserResult, to element: HTMLComponent.Element, ancestors: [CSSEntity], previousSiblings: [CSSEntity], currentAttributes: Attributes) -> Attributes {
            var result = currentAttributes
            
            let properties = css.match(entity: element.cssEntity, ancestors: ancestors, previousSiblings: previousSiblings)
            for (key, value) in properties {
                switch key {
                case .textAlign:
                    guard let textAlign = CSSTextAlign(from: value) else { continue }
                    result.textAlign = textAlign
                case .color:
                    guard let color = CSSColor(from: value) else { continue }
                    result.color = color
                case .width:
                    guard let width = CSSNumericValue(string: value) else { continue }
                    result.width = width
                case .height:
                    guard let height = CSSNumericValue(string: value) else { continue }
                    result.height = height
                case .display:
                    guard let display = CSSDisplay(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else { continue }
                    result.display = display
                case .fontStyle:
                    guard let fontStyle = CSSFontStyle(string: value) else { continue }
                    result.fontStyle = fontStyle
                case .fontWeight:
                    guard let fontWeight = CSSFontWeight(string: value) else { continue }
                    result.fontWeight = fontWeight
                case .fontSize:
                    guard let fontSize = CSSFontSize(string: value) else { continue }
                    result.fontSize = fontSize
                case .font:
                    applyFontProperty(value, to: &result)
                case .margin:
                    applyMarginProperty(value, to: &result)
                case .marginTop:
                    guard let margin = CSSNumericValue(string: value) else { continue }
                    result.marginTop = margin
                case .marginBottom:
                    guard let margin = CSSNumericValue(string: value) else { continue }
                    result.marginBottom = margin
                case .marginLeft:
                    guard let margin = CSSNumericValue(string: value) else { continue }
                    result.marginLeft = margin
                case .marginRight:
                    guard let margin = CSSNumericValue(string: value) else { continue }
                    result.marginRight = margin
                case .padding:
                    applyPaddingProperty(value, to: &result)
                case .paddingTop:
                    guard let padding = CSSNumericValue(string: value) else { continue }
                    result.paddingTop = padding
                case .paddingBottom:
                    guard let padding = CSSNumericValue(string: value) else { continue }
                    result.paddingBottom = padding
                case .paddingLeft:
                    guard let padding = CSSNumericValue(string: value) else { continue }
                    result.paddingLeft = padding
                case .paddingRight:
                    guard let padding = CSSNumericValue(string: value) else { continue }
                    result.paddingRight = padding
                default:
                    break
                }
            }
            return result
        }
        
        // MARK: - CSS Helper
        
        private func applyFontProperty(_ value: String, to attributes: inout Attributes) {
            let font = CSSFont(string: value)
            if let size = font.fontSize {
                attributes.fontSize = size
            }
            if let weight = font.fontWeight {
                attributes.fontWeight = weight
            }
            if let style = font.fontStyle {
                attributes.fontStyle = style
            }
            if let family = font.fontFamily {
                attributes.fontFamily = family
            }
        }
        
        private func applyMarginProperty(_ value: String, to attributes: inout Attributes) {
            guard let margins = CSSInsets(from: value) else { return }
            if let top = margins.top {
                attributes.marginTop = top
            }
            if let bottom = margins.bottom {
                attributes.marginBottom = bottom
            }
            if let left = margins.left {
                attributes.marginLeft = left
            }
            if let right = margins.right {
                attributes.marginRight = right
            }
        }
        
        private func applyPaddingProperty(_ value: String, to attributes: inout Attributes) {
            guard let paddings = CSSInsets(from: value) else { return }
            if let top = paddings.top {
                attributes.paddingTop = top
            }
            if let bottom = paddings.bottom {
                attributes.paddingBottom = bottom
            }
            if let left = paddings.left {
                attributes.paddingLeft = left
            }
            if let right = paddings.right {
                attributes.paddingRight = right
            }
        }
    }
}

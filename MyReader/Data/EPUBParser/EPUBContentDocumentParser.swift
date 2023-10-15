//
//  EPUBContentDocumentParser.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import Foundation
import UIKit.UIColor

final class EPUBContentDocumentParser: NSObject, XMLParserDelegate {
    
    // MARK: - Nested Types
    
    private struct BuildDocumentResult {
        fileprivate struct Element {
            let element: DocumentResult.Element
            let requestNewLine: Bool
        }
        
        let elements: [Element]
        let requestNewLine: Bool
    }
    
    // MARK: - Properties
    
    private let htmlParser = HTMLParser()
    private var stylesForCurrentDocument: [CSSParserResult] = []
    
    private let cssParser = CSSParser()
    private var styles: [URL: CSSParserResult] = [:]
    
    private static let baseStyle: CSSParserResult? = {
        guard let url = Bundle.main.url(forResource: "base", withExtension: "css") else {
            return nil
        }
        return CSSParser().parse(url: url)
    }()
    
    // MARK: - Interface
    
    func parse(url: URL) -> DocumentResult? {
        guard let component = htmlParser.parse(url: url) else {
            return nil
        }
        
        stylesForCurrentDocument = [Self.baseStyle].compactMap({ $0 })
        
        let buildDocumentResultElements = buildDocumentResult(from: component, url: url)
        let elements = convertToDocumentElement(buildDocumentResultElements.elements)
        return DocumentResult(elements: elements)
    }
    
    // MARK: - Logic
    
    private func buildDocumentResult(from component: HTMLComponent, url: URL, attributes: DocumentResult.Element.Attributes = .init(), componentsStack: [HTMLComponent] = [], requestNewLine rnl: Bool = false) -> BuildDocumentResult {
        switch component {
        case .text(let text):
            if text != "" {
                return BuildDocumentResult(elements: [.init(element: .init(elementType: .text(text), attributes: attributes), requestNewLine: rnl)], requestNewLine: false)
            } else {
                return BuildDocumentResult(elements: [], requestNewLine: rnl)
            }
        case .element(let element):
            guard element.name != .head else {
                loadResourcesFrom(headComponents: element.components, documentUrl: url)
                return BuildDocumentResult(elements: [], requestNewLine: false)
            }
            
            var requestNewLine = rnl
            var newAttributes = apply(htmlAttributes: element.attributes, to: attributes)
            
            let classes = Set((element.attributes["class"] ?? "").components(separatedBy: " ").filter({ $0.isEmpty == false }).map({ String($0) }))
            let entity = CSSEntity(element: element.name, classes: classes, id: element.attributes["id"])
            
            for style in stylesForCurrentDocument {
                newAttributes = apply(css: style, to: entity, currentAttributes: newAttributes)
            }
            
            let isBlock = (newAttributes.display ?? .block) == .block
            if isBlock {
                requestNewLine = true
            }
            
            var result: [BuildDocumentResult.Element] = []
            if element.name == .img, let src = element.attributes["src"] {
                result.append(.init(element: .init(elementType: .image(src), attributes: newAttributes), requestNewLine: requestNewLine))
            }
            
            for component in element.components {
                let componentResult = buildDocumentResult(from: component, url: url, attributes: newAttributes, requestNewLine: requestNewLine)
                result.append(contentsOf: componentResult.elements)
                requestNewLine = componentResult.requestNewLine
            }
            
            
            return BuildDocumentResult(elements: result, requestNewLine: isBlock || requestNewLine)
            
//            return result + element.components.flatMap { buildDocumentResult(from: $0, url: url, attributes: newAttributes)}
        }
    }
    
    // TODO: Add ancestors and previous siblings
    private func apply(css: CSSParserResult, to entity: CSSEntity, currentAttributes: DocumentResult.Element.Attributes) -> DocumentResult.Element.Attributes {
        var result = currentAttributes
        
        let properties = css.match(entity: entity, ancestors: [], previousSiblings: [])
        for (key, value) in properties {
            switch key {
            case .textAlign:
                guard let textAlign = CSSTextAlign(from: value) else { continue }
                result.textAlign = textAlign.textAlign
            case .color:
                guard let color = CSSColor(from: value) else { continue }
                result.textColor = color.uiColor
            case .width:
                guard let width = CSSNumericValue(string: value) else { continue }
                result.width = width
            case .height:
                guard let height = CSSNumericValue(string: value) else { continue }
                result.height = height
            case .display:
                guard let display = CSSDisplay(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else { continue }
                result.display = display
            default:
                break
            }
        }
        
        return result
    }
    
    private func apply(htmlAttributes: [String: String], to attributes: DocumentResult.Element.Attributes) -> DocumentResult.Element.Attributes {
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
    
    private func loadResourcesFrom(headComponents: [HTMLComponent], documentUrl: URL) {
        for component in headComponents {
            guard case .element(let element) = component else {
                continue
            }
            switch element.name {
            case .link:
                guard let rel = element.attributes["rel"],
                      let href = element.attributes["href"],
                      let typeString = element.attributes["type"],
                      let type = HTMLElementType(from: typeString) else {
                    continue
                }
                switch rel {
                case "stylesheet":
                    guard type == .textCss else {
                        continue
                    }
                    
                    let fileUrl = documentUrl.deletingLastPathComponent().appendingPathComponent(href)
                    
                    if let style = loadStyle(from: fileUrl) {
                        stylesForCurrentDocument.append(style)
                    }
                default:
                    print("\(rel) relationship is not handled")
                    
                }
            default:
                break
            }
        }
    }
    
    private func loadStyle(from url: URL) -> CSSParserResult? {
        guard styles[url] == nil else {
            return styles[url]
        }
        
        guard let cssResult = cssParser.parse(url: url) else {
            return nil
        }
        
        styles[url] = cssResult
        return cssResult
    }
    
    private func convertToDocumentElement(_ buildResult: [BuildDocumentResult.Element]) -> [DocumentResult.Element] {
        var result = buildResult.map({ $0.element })
        for index in 0..<buildResult.count - 1 {
            if buildResult[index + 1].requestNewLine {
                if case .text(let text) = result[index].elementType {
                    result[index].elementType = .text(text + "\n")
                }
            }
        }
        return result
    }
    
    private func htmlElementToCSSEntity(_ e: HTMLComponent.Element) -> CSSEntity {
        let classes = Set((e.attributes["class"] ?? "").components(separatedBy: " ").filter({ $0.isEmpty == false }).map({ String($0) }))
        return CSSEntity(element: e.name, classes: classes, id: e.attributes["id"])
    }
}

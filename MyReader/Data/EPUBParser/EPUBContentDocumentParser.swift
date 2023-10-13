//
//  EPUBContentDocumentParser.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import Foundation
import UIKit.UIColor

final class EPUBContentDocumentParser: NSObject, XMLParserDelegate {
    
    // MARK: - Properties
    
    private let htmlParser = HTMLParser()
    private var stylesForCurrentDocument: [CSSParser.Result] = []
    
    private let cssParser = CSSParser()
    private var styles: [URL: CSSParser.Result] = [:]
    
    private lazy var baseStyle: CSSParser.Result? = {
        guard let url = Bundle.main.url(forResource: "base", withExtension: "css") else {
            return nil
        }
        return cssParser.parse(url: url)
    }()
    
    // MARK: - Interface
    
    func parse(url: URL) -> DocumentResult? {
        guard let component = htmlParser.parse(url: url) else {
            return nil
        }
        
        stylesForCurrentDocument = [baseStyle].compactMap({ $0 })
        return DocumentResult(elements: buildDocumentResult(from: component, url: url))
    }
    
    // MARK: - Logic
    
    private func buildDocumentResult(from component: HTMLComponent, url: URL, attributes: DocumentResult.Element.Attributes = .init()) -> [DocumentResult.Element] {
        var newAttributes = attributes
        var result: [DocumentResult.Element] = []
        
        switch component {
        case .text(let text):
            if text != "" {
                return [.init(elementType: .text(text), attributes: attributes)]
            } else {
                return []
            }
        case .element(let element):
            guard element.name != .head else {
                loadResourcesFrom(headComponents: element.components, documentUrl: url)
                return []
            }
            
            if let width = element.attributes["width"], let widthValue = CSSNumericValue(string: width) {
                newAttributes.width = widthValue
            }
            if let height = element.attributes["height"], let heightValue = CSSNumericValue(string: height) {
                newAttributes.height = heightValue
            }
            

            switch element.name {
            case .a:
                newAttributes.link = .init(link: element.attributes["href"])
            case .div, .p:
                result.append(.init(elementType: .text("\n\n"), attributes: newAttributes))
            case .h1, .h2, .h3, .h4, .h5, .h6:
//                newAttributes.font.traits.insert(.traitBold)
//
//                let multiplier: CGFloat
//                switch element.name {
//                case .h1: multiplier = 2.5
//                case .h2: multiplier = 2.1
//                case .h3: multiplier = 1.8
//                case .h4: multiplier = 1.5
//                case .h5: multiplier = 1.3
//                default: multiplier = 1.15
//                }
//                newAttributes.font.sizeMultiplier = multiplier
                
                result.append(.init(elementType: .text("\n\n"), attributes: newAttributes))
            case .img:
                if let src = element.attributes["src"] {
                    newAttributes.image = .init(alt: element.attributes["alt"])
                    result.append(.init(elementType: .image(src), attributes: newAttributes))
                }
//            case .em:
//                newAttributes.font.traits.insert(.traitItalic)
            case .br:
                result.append(.init(elementType: .text("\n"), attributes: newAttributes))
            default:
                break
            }
            
            for style in stylesForCurrentDocument {
                newAttributes = apply(css: style, to: element, currentAttributes: newAttributes)
            }
            
            return result + element.components.flatMap { buildDocumentResult(from: $0, url: url, attributes: newAttributes)}
        }
    }
    
    private func apply(css: CSSParser.Result, to element: HTMLComponent.Element, currentAttributes: DocumentResult.Element.Attributes) -> DocumentResult.Element.Attributes {
        var result = currentAttributes
        
        let classes = Set((element.attributes["class"] ?? "").components(separatedBy: " ").map({ String($0) }))
        let properties = css.match(element: element.name, classes: classes, id: element.attributes["id"])
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
//            case .fontStyle:
                
            default:
                break
            }
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
    
    private func loadStyle(from url: URL) -> CSSParser.Result? {
        guard styles[url] == nil else {
            return styles[url]
        }
        
        guard let cssResult = cssParser.parse(url: url) else {
            return nil
        }
        
        styles[url] = cssResult
        return cssResult
    }
}

//
//  EPUBContentDocumentParser.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import Foundation
import UIKit.UIColor

final class EPUBContentDocumentParser: NSObject, XMLParserDelegate {
    
    struct DocumentResult {
        struct Element {
            let text: String
            let attributes: Attributes
            
            struct Attributes {
                struct Font {
                    enum Style {
                        case italic
                        case bold
                    }
                    
                    var styles: Set<Style>
                    var sizeMultiplier: CGFloat
                    
                    var isNormal: Bool {
                        return styles.isEmpty
                    }
                    
                    init(styles: Set<Style> = [], sizeMultiplier: CGFloat = 1) {
                        self.styles = styles
                        self.sizeMultiplier = sizeMultiplier
                    }
                }
                
                var textColor: UIColor?
                var font: Font?
            }
        }
        
        let elements: [Element]
    }
    
    enum HTMLComponent: CustomStringConvertible {
        var description: String {
            switch self {
            case .text(let text):
                return text
            case .element(let element):
                let childPrint = element.components.map({ $0.description }).joined()
                return "\n<\(element.name)>\n\(childPrint)\n</\(element.name)>"
            }
        }
        
        class Element {
            let name: HTMLElement
            let attributes: [String: String]
            var components: [HTMLComponent]
            
            init(name: HTMLElement, attributes: [String : String], components: [HTMLComponent]) {
                self.name = name
                self.attributes = attributes
                self.components = components
            }
        }
        
        case text(String)
        case element(Element)
        
        func getLastElement(depth: Int) -> Element? {
            switch self {
            case .element(let element):
                if depth <= 1 {
                    return element
                } else {
                    return element.components.last?.getLastElement(depth: depth - 1)
                }
            default:
                return nil
            }
        }
    }
    
    enum CSSSelectorType {
        case all
        case id(String)
        case elements([String])
        case classes([String])
        case classDescendant(String, String)
        case elementWithClass(String, String)
        case elementInsideElement(String, String)
        case elementParentOfElement(String, String)
        case elementImmediatelyAfterElement(String, String)
        case elementPrecededElements(String, String)
    }
    
    struct CSSSelector {
        let cssSelectorType: CSSSelectorType
        let pseudoClass: String?
        let pseudoElement: String?
    }
    
    enum CSSPropertyValue {
        case string(String)
        case double(Double)
        case int(Int)
        case other(Any)
    }
    
    enum HTMLElement: Hashable {
        case body
        case a
        case p
        case div
        case h1
        case h2
        case h3
        case h4
        case h5
        case h6
        case head
        case other(String)
        
        init(from: String) {
            switch from {
            case "body": self = .body
            case "a": self = .a
            case "div": self = .div
            case "p": self = .p
            case "h1": self = .h1
            case "h2": self = .h2
            case "h3": self = .h3
            case "h4": self = .h4
            case "h5": self = .h5
            case "h6": self = .h6
            case "head": self = .head
            default: self = .other(from)
            }
        }
    }
    
    // MARK: - Properties
    
    private var component: HTMLComponent?
    private var currentComponentDepthLevel = 0
    private let cssParser = CSSParser()

    private var styles: [URL: CSSParser.Result] = [:]
    
    private var baseUrl: URL?
    
    // MARK: - Interface
    
    // Version 1: Just text, dont think about images at all. It will be faster to implement this way and then rebuild, because I will spend more time coding and actually understanding then reading.
    
    func parse(url: URL) -> DocumentResult? {
        let d1 = Date()
        guard let parser = XMLParser(contentsOf: url) else {
            return nil
        }
        let d2 = Date()
        let t1 = d2.timeIntervalSince(d1)
        if t1 > 0.05 {
//            print("t1 = \(t1)")
        }
        
        baseUrl = url.deletingLastPathComponent()
        
        currentComponentDepthLevel = 0
        component = nil
        
        parser.delegate = self
        parser.parse()
        
        let d3 = Date()
//        print("Time2 = \(d3.timeIntervalSince(d2))")
        
        guard let component = component else {
            return nil
        }
        
        let result = DocumentResult(elements: buildDocumentResult(from: component))
        let d4 = Date()
//        print("Time3 = \(d4.timeIntervalSince(d3))")
        return result
    }
    
    // MARK: - Logic
    
    private func buildDocumentResult(from component: HTMLComponent, attributes: DocumentResult.Element.Attributes = .init()) -> [DocumentResult.Element] {
        var newAttributes = attributes
        var result: [DocumentResult.Element] = []
        
        switch component {
        case .text(let text):
            if text != "" {
                return [.init(text: text, attributes: attributes)]
            } else {
                return []
            }
        case .element(let element):
            switch element.name {
            case .head:
                loadResourcesFrom(head: component)
                return []
            case .a:
                newAttributes.textColor = .red
            case .div, .p:
                result.append(.init(text: "\n\n", attributes: newAttributes))
            case .h1, .h2, .h3, .h4, .h5, .h6:
                var font = attributes.font ?? .init()
                font.styles.insert(.bold)
                
                let multiplier: CGFloat
                switch element.name {
                case .h1: multiplier = 2.5
                case .h2: multiplier = 2.1
                case .h3: multiplier = 1.8
                case .h4: multiplier = 1.5
                case .h5: multiplier = 1.3
                default: multiplier = 1.15
                }
                font.sizeMultiplier = multiplier
                newAttributes.font = font
                
                result.append(.init(text: "\n\n", attributes: newAttributes))
            default:
                break
            }
            
            return result + element.components.flatMap { buildDocumentResult(from: $0, attributes: newAttributes)}
        }
    }
    
    private func loadResourcesFrom(head: HTMLComponent) {
        // TODO: Implement
        
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if currentComponentDepthLevel == 0 {
            component = .element(.init(name: .init(from: elementName), attributes: attributeDict, components: []))
        } else if let component = component {
            guard let lastElement = component.getLastElement(depth: currentComponentDepthLevel) else {
                fatalError("Should present")
            }
            
            lastElement.components.append(.element(.init(name: .init(from: elementName), attributes: attributeDict, components: [])))
        } else {
            fatalError("No component")
        }
        currentComponentDepthLevel += 1
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentComponentDepthLevel -= 1
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let lastElement = component?.getLastElement(depth: currentComponentDepthLevel) else {
            fatalError("No element")
        }
        
        lastElement.components.append(.text(string.trimmingCharacters(in: .whitespacesAndNewlines)))
    }
    
    // MARK: - Helpers
    
    private func apply(style: CSSParser.Result) {
        
    }
}

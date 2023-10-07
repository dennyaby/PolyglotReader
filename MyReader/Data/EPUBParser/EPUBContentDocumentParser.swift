//
//  EPUBContentDocumentParser.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import Foundation
import UIKit.UIColor

final class EPUBContentDocumentParser: NSObject, XMLParserDelegate {
    
    struct NumericValue {
        
        let points: CGFloat
        
        // let pixes: CGFloat
        
        // MARK: - Init
        
        init?(string: String?) {
            guard let string = string, let doubleValue = Double(string) else {
//                fatalError("Should handle as some value")
                return nil
            }
            self.init(points: CGFloat(doubleValue))
            // TODO: Handle all possible formats
        }
        
        init(points: CGFloat) {
            self.points = points
        }
        
        // MARK: - Operators
        
        static func *(lhs: NumericValue, rhs: NumericValue) -> NumericValue {
            return .init(points: lhs.points * rhs.points)
        }
        
        static func *(lhs: NumericValue, rhs: CGFloat) -> NumericValue {
            return .init(points: lhs.points * rhs)
        }
        
        static func /(lhs: NumericValue, rhs: NumericValue) -> NumericValue {
            return .init(points: lhs.points / rhs.points)
        }
        
        static func /(lhs: NumericValue, rhs: CGFloat) -> NumericValue {
            return .init(points: lhs.points / rhs)
        }
    }
    
    struct DocumentResult {
        struct Element {
            struct Attributes {
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
                
                struct Link {
                    var link: String?
                }
                
                var textColor: UIColor?
                var font = Font()
                var image = Image()
                var link = Link()
                var width: NumericValue?
                var height: NumericValue?
            }
            
            enum ElementType {
                case text(String)
                case image(String)
            }
            
            let elementType: ElementType
            let attributes: Attributes
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
    
    enum ElementType {
        case textCss
        
        init?(from: String) {
            switch from {
            case "text/css":
                self = .textCss
            default:
                return nil
            }
        }
    }
    
    // MARK: - Properties
    
    private var component: HTMLComponent?
    private var currentComponentDepthLevel = 0
    private var stylesToUse: [CSSParser.Result] = []
    
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
        stylesToUse = []
        
        parser.delegate = self
        parser.parse()
        
        let d3 = Date()
//        print("Time2 = \(d3.timeIntervalSince(d2))")
        
        guard let component = component else {
            return nil
        }
        
        let result = DocumentResult(elements: buildDocumentResult(from: component, url: url))
        let d4 = Date()
//        print("Time3 = \(d4.timeIntervalSince(d3))")
        return result
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
            
            if let width = element.attributes["width"], let widthValue = NumericValue(string: width) {
                newAttributes.width = widthValue
            }
            if let height = element.attributes["height"], let heightValue = NumericValue(string: height) {
                newAttributes.height = heightValue
            }
            
            switch element.name {
            case .a:
                newAttributes.link = .init(link: element.attributes["href"])
            case .div, .p:
                result.append(.init(elementType: .text("\n\n"), attributes: newAttributes))
            case .h1, .h2, .h3, .h4, .h5, .h6:
                newAttributes.font.traits.insert(.traitBold)
                
                let multiplier: CGFloat
                switch element.name {
                case .h1: multiplier = 2.5
                case .h2: multiplier = 2.1
                case .h3: multiplier = 1.8
                case .h4: multiplier = 1.5
                case .h5: multiplier = 1.3
                default: multiplier = 1.15
                }
                newAttributes.font.sizeMultiplier = multiplier

                result.append(.init(elementType: .text("\n\n"), attributes: newAttributes))
            case .img:
                if let src = element.attributes["src"] {
                    newAttributes.image = .init(alt: element.attributes["alt"])
                    result.append(.init(elementType: .image(src), attributes: newAttributes))
                }
            case .em:
                newAttributes.font.traits.insert(.traitItalic)
            case .br:
                result.append(.init(elementType: .text("\n"), attributes: newAttributes))
            default:
                break
            }
            
            return result + element.components.flatMap { buildDocumentResult(from: $0, url: url, attributes: newAttributes)}
        }
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
                      let type = ElementType(from: typeString) else {
                    continue
                }
                switch rel {
                case "stylesheet":
                    guard type == .textCss else {
                        continue
                    }
                    
                    let fileUrl = documentUrl.deletingLastPathComponent().appendingPathComponent(href)
                    
                    if let style = loadStyle(from: fileUrl) {
                        stylesToUse.append(style)
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
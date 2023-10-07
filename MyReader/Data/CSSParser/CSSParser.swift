//
//  CSSParser.swift
//  MyReader
//
//  Created by  Dennya on 23/09/2023.
//

import Foundation
/*
 Give every selector hash value with some logic - for example plain is "element.class#id". When one after another - "element1\nelement2. Then from html construct all possible combinations of selector and try to get values from selectors hash table.
 
 */

final class CSSParser {
    
    // MARK: - Nested Types
    
    typealias Properties = [CSSProperty: String]
    
    enum HTMLElementKey: Hashable {
        case any
        case element(HTMLElement)
    }
    
    enum HTMLIDKey: Hashable {
        case any
        case id(String)
    }
    
    enum HTMLClassesKey: Hashable {
        case any
        case classes(Set<String>)
    }
    
    struct CSSSelector: Hashable {
        let element: HTMLElement?
        let classes: Set<String>
        let id: String?
    }
    
    static let selectorsRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "([a-z0-9#\\.]+)[\\n\\r\\s\\t]*\\{([^\\}]*)\\}")
    }()
    
    static let propertiesRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "([a-z-]*)[\\s]*:[\\s]*(.*);")
    }()
    
    static let selectorComponentsRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "^([a-z0-9_-]+)?(\\.[a-z0-9_-]+)*(#[a-z0-9_-]+)?")
    }()
    
    static let elementSelectorRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "^[a-zA-Z0-9_-]+")
    }()
    
    static let classSelectorRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "\\.[a-zA-Z0-9_-]+")
    }()
    
    static let idSelectorRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "#[a-zA-Z0-9_-]+")
    }()
    
    // MARK: - Interface
    
    func parse(url: URL) -> Result? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        guard let fileString = String(data: data, encoding: .utf8) else {
            return nil
        }
//        print(fileString)
        
        return parse(string: fileString)
    }
    
    func parse(string: String) -> Result? {
        guard let selectorRegExp = Self.selectorsRegularExpression,
              let propertyRegExp = Self.propertiesRegularExpression else {
            return nil
        }
        
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        
        var selectors: [CSSSelector: [CSSProperty: String]] = [:]
        
        selectorRegExp.enumerateMatches(in: string, options: [], range: range) { match, _, stop in
            guard let match = match else { return }
            guard match.numberOfRanges == 3 else { return }
            
            guard let selectorRange = Range(match.range(at: 1), in: string) else { return }
            let selectorString = String(string[selectorRange])
            let selector = self.selector(from: selectorString)
            
            guard let bodyRange = Range(match.range(at: 2), in: string) else { return }
            let body = String(string[bodyRange])
            
            let properties = self.bodyValues(from: body, regex: propertyRegExp)
            selectors[selector] = properties
        }
        
        return Result(css: buildCSSTree(from: selectors))
    }
    
    /*
     
     <p class="class1 class2" id="myid">
     
     * {
        font-color: brown;
     }
     
     p { color = white; }
     
     .class1 {
        color = red;
     }
     
     p.class2 {
        background-color: blue;
     }
     
     p.class1#myid {
        text-align: center;
        color = black;
     }
     
     css[.p] = [.any: [.any: [color = white],
                       .classes("class2"): [background-color: blue],
                .id(myid): [.classes("class1"): [text-align: center; color = black;]
     
     
     css[.any] = [.any: [.classes("class1"): [color: red]]
     
     
     css[.p][.any][.any] + css[.any][.any][.classes(class1, class2)] + css[
     
     // When adding info from selectors to classes, for example we have .c1, .c2 and .c1.c2 - We add properties from .c1 to [.classes(c1)], properties from .c2 to [.classes(c2)], and properties from .c1, .c2 and .c1.c2 to [.classes(c1, c2)]
     
     */
    
    // MARK: - Helper
    
    private func buildCSSTree(from selectors: [CSSSelector: [CSSProperty: String]]) -> Result.CSSTree {
        var result: Result.CSSTree = [:]
        
        for (selector, properties) in selectors {
            let elementKey: HTMLElementKey
            if let element = selector.element {
                elementKey = .element(element)
            } else {
                elementKey = .any
            }
            
            let classesKey: HTMLClassesKey = selector.classes.isEmpty ? .any : .classes(selector.classes)
            let idKey: HTMLIDKey
            if let id = selector.id {
                idKey = .id(id)
            } else {
                idKey = .any
            }
            
            if result[elementKey] == nil {
                result[elementKey] = [:]
            }
            
            if result[elementKey]?[classesKey] == nil {
                result[elementKey]?[classesKey] = [:]
            }
            
            result[elementKey]?[classesKey]?[idKey] = properties
        }
        
        return result
    }
    
    private func selector(from string: String) -> CSSSelector {
        // TODO: Handle * selector
        var element: HTMLElement?
        var classes: Set<String> = []
        var id: String?
        
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        Self.elementSelectorRegularExpression?.enumerateMatches(in: string, range: range, using: { match, _, stop in
            guard let match = match, let range = Range(match.range, in: string) else { return }
            
            element = .init(from: String(string[range]))
        })
        
        Self.classSelectorRegularExpression?.enumerateMatches(in: string, range: range, using: { match, _, stop in
            guard let match = match, let range = Range(match.range, in: string) else { return }
            
            classes.insert(String(string[range].dropFirst()))
        })
        
        Self.idSelectorRegularExpression?.enumerateMatches(in: string, range: range, using: { match, _, stop in
            guard let match = match, let range = Range(match.range, in: string) else { return }
            
            id = String(string[range].dropFirst())
        })
  
        return CSSSelector(element: element, classes: classes, id: id)
    }
    
    private func bodyValues(from string: String, regex: NSRegularExpression) -> [CSSProperty: String] {
        var result: [CSSProperty: String] = [:]
        
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        regex.enumerateMatches(in: string, range: range) { match, _, stop in
            guard let match = match else { return }
            guard match.numberOfRanges == 3 else { return }
            
            guard let propertyRange = Range(match.range(at: 1), in: string) else { return }
            guard let valueRange = Range(match.range(at: 2), in: string) else { return }
            
            guard let property = CSSProperty(rawValue: String(string[propertyRange])) else {
                print("Cannot handle css property \(String(string[propertyRange]))")
                return
            }
            result[property] = String(string[valueRange])
        }
        
        return result
    }
    
}

//
//  CSSParser.swift
//  MyReader
//
//  Created by  Dennya on 23/09/2023.
//

import Foundation

final class CSSParser {
    
    // MARK: - Nested Types
    
    typealias Properties = [CSSProperty: String]
    
    static let selectorsRegularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "([^\\{^\\}]+)\\{([^\\}]*)\\}")
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
    
    func parse(url: URL) -> CSSParserResult? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        guard let fileString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return parse(string: fileString)
    }
    
    func parse(string: String) -> CSSParserResult? {
        guard let selectorRegExp = Self.selectorsRegularExpression,
              let propertyRegExp = Self.propertiesRegularExpression else {
            return nil
        }
        
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        
        var selectors: [CSSSelector: Properties] = [:]
        
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
        
        return CSSParserResult(selectors: selectors)
    }
    
    // MARK: - Helper
    
    private func selector(from string: String) -> CSSSelector {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized == "*" {
            return .all
        }
        
        let entities = normalized.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines)})
        if entities.count > 1 {
            return .entities(entities.map(cssEntity(from:)))
        } else {
            let childItems = normalized.split(separator: ">", maxSplits: 1)
            if childItems.count == 2 {
                let parent = childItems[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let child = childItems[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return .child(cssEntity(from: parent), cssEntity(from: child))
            }
            
            let nextSiblingItems = normalized.split(separator: "+", maxSplits: 1)
            if nextSiblingItems.count == 2 {
                let firstSibling = nextSiblingItems[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let nextSibling = nextSiblingItems[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return .nextSibling(cssEntity(from: firstSibling), cssEntity(from: nextSibling))
            }
            
            let subsequentSiblingsItems = normalized.split(separator: "~", maxSplits: 1)
            if subsequentSiblingsItems.count == 2 {
                let firstSibling = subsequentSiblingsItems[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let secondSibling = subsequentSiblingsItems[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return .subsequentSibling(cssEntity(from: firstSibling), cssEntity(from: secondSibling))
            }
            
            let descendantItems = normalized.split(separator: " ").filter({ $0.isEmpty == false })
            if descendantItems.count == 2 {
                let parent = descendantItems[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let descendant = descendantItems[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return .descendant(cssEntity(from: parent), cssEntity(from: descendant))
            }
            
            return .entities([cssEntity(from: normalized)])
        }
    }
    
    
    private func cssEntity(from string: String) -> CSSEntity {
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
  
        return CSSEntity(element: element, classes: classes, id: id)
    }
    
    private func bodyValues(from string: String, regex: NSRegularExpression) -> Properties {
        var result: Properties = [:]
        
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        regex.enumerateMatches(in: string, range: range) { match, _, stop in
            guard let match = match else { return }
            guard match.numberOfRanges == 3 else { return }
            
            guard let propertyRange = Range(match.range(at: 1), in: string) else { return }
            guard let valueRange = Range(match.range(at: 2), in: string) else { return }
            
            let propertyName = String(string[propertyRange]).lowercased()
            guard let property = CSSProperty(rawValue: propertyName) else {
                print("Cannot handle css property \(propertyName)")
                return
            }
            result[property] = String(string[valueRange])
        }
        
        return result
    }
}

//
//  HTMLParser.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import Foundation

final class HTMLParser: NSObject, XMLParserDelegate {
    
    // MARK: - Properties
    
    private var currentComponentDepthLevel = 0
    private var component: HTMLComponent?
    private var baseUrl: URL?
    
    // MARK: - Interface
    
    func parse(url: URL) -> HTMLComponent? {
        guard let xmlParser = XMLParser(contentsOf: url) else {
            return nil
        }
        
        currentComponentDepthLevel = 0
        component = nil
        
        xmlParser.delegate = self
        if xmlParser.parse() == false {
            return nil
        }
        
        return component
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
        
        let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty == false {
            lastElement.components.append(.text(text))
        }
    }
}

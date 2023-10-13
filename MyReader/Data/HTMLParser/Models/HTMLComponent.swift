//
//  HTMLComponent.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import Foundation

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

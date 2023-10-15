//
//  HTMLComponent.swift
//  MyReader
//
//  Created by  Dennya on 09/10/2023.
//

import Foundation

enum HTMLComponent: CustomStringConvertible, Equatable {
    var description: String {
        switch self {
        case .text(let text):
            return text
        case .element(let element):
            let childPrint = element.components.map({ $0.description }).joined()
            return "\n<\(element.name)>\n\(childPrint)\n</\(element.name)>"
        }
    }
    
    class Element: Equatable {
        
        // MARK: - Properties
        
        let name: HTMLElement
        let attributes: [String: String]
        var components: [HTMLComponent]
        
        // MARK: - Init
        
        init(name: HTMLElement, attributes: [String : String], components: [HTMLComponent]) {
            self.name = name
            self.attributes = attributes
            self.components = components
        }
        
        // MARK: - Equatable
        
        static func == (lhs: HTMLComponent.Element, rhs: HTMLComponent.Element) -> Bool {
            guard lhs.name == rhs.name else {
                return false
            }
            
            guard lhs.attributes == rhs.attributes else {
                return false
            }
            
            return lhs.components == rhs.components
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

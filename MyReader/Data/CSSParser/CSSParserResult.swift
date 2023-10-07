//
//  CSSParserResult.swift
//  MyReader
//
//  Created by  Dennya on 07/10/2023.
//

import Foundation

extension CSSParser {
    class Result {
        
        typealias CSSTree = [HTMLElementKey: [HTMLClassesKey: [HTMLIDKey: Properties]]]
        
        // MARK: - Properties
        
        private let css: CSSTree
        
        // MARK: - Init
        
        init(css: CSSTree) {
            self.css = css
        }
        
        // MARK: - Interface
        
        func match(element: HTMLElement, classes: Set<String> = [], id: String? = nil) -> Properties {
            var result: Properties = [:]
            
            var propertiesToMatch: [Properties?] = []
            
            let elementKeys: [HTMLElementKey] = [.any, .element(element)]
            
            for elementKey in elementKeys {
                propertiesToMatch.append(css[elementKey]?[.any]?[.any])
            }
            
            var idKeys: [HTMLIDKey] = [.any]
            if let id = id {
                idKeys.append(.id(id))
            }
            if classes.isEmpty == false {
                var propertiesForAnyId = true
                while true {
                    for elementKey in elementKeys {
                        let classesToUse = css[elementKey]?.filter({ key, _ in
                            switch key {
                            case .any: return false
                            case .classes(let htmlClasses): return htmlClasses.isSubset(of: classes)
                            }
                        })
                        
                        classesToUse?.forEach({ _, values in
                            if propertiesForAnyId {
                                propertiesToMatch.append(values[.any])
                            } else if let id = id {
                                propertiesToMatch.append(values[.id(id)])
                            }
                        })
                    }
                    if let id = id, propertiesForAnyId {
                        for elementKey in elementKeys {
                            propertiesToMatch.append(css[elementKey]?[.any]?[.id(id)])
                        }
                        propertiesForAnyId = false
                    } else {
                        break
                    }
                }
            } else {
                if let id = id {
                    for elementKey in elementKeys {
                        propertiesToMatch.append(css[elementKey]?[.any]?[.id(id)])
                    }
                }
            }
            
            for properties in propertiesToMatch.compactMap({ $0 }) {
                result.merge(properties, uniquingKeysWith: { current, next in next })
            }
            
            return result
        }
    }
}

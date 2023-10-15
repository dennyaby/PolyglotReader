//
//  CSSParserResult.swift
//  MyReader
//
//  Created by  Dennya on 15/10/2023.
//

import Foundation

struct CSSParserResult {
    
    typealias Properties = [CSSProperty: String]
    
    // MARK: - Properties
    
    private var entitiesTree: CSSTree<Properties> = .init()
    private var childEntitiesTree: CSSTree<CSSTree<Properties>> = .init()
    private var descendantEntitiesTree: CSSTree<CSSTree<Properties>> = .init()
    private var nextSiblingEntitiesTree: CSSTree<CSSTree<Properties>> = .init()
    private var subsequentSiblingEntitiesTree: CSSTree<CSSTree<Properties>> = .init()
    
    // MARK: - Init
    
    init(selectors: [CSSSelector: Properties]) {
        for (selector, properties) in selectors {
            switch selector {
            case .all:
                entitiesTree.add(value: properties, for: .init())
                break
            case .entities(let entities):
                for entity in entities {
                    entitiesTree.add(value: properties, for: entity)
                }
                break
            case .child(let parent, let child):
                var subtree = childEntitiesTree.value(for: parent) ?? CSSTree()
                subtree.add(value: properties, for: child)
                childEntitiesTree.set(value: subtree, for: parent)
            case .descendant(let parent, let descendant):
                var subtree = descendantEntitiesTree.value(for: parent) ?? CSSTree()
                subtree.add(value: properties, for: descendant)
                descendantEntitiesTree.set(value: subtree, for: parent)
            case .nextSibling(let firstSibling, let nextSibling):
                var subtree = nextSiblingEntitiesTree.value(for: firstSibling) ?? CSSTree()
                subtree.add(value: properties, for: nextSibling)
                nextSiblingEntitiesTree.set(value: subtree, for: firstSibling)
            case .subsequentSibling(let firstSibling, let subsequentSibling):
                var subtree = subsequentSiblingEntitiesTree.value(for: firstSibling) ?? CSSTree()
                subtree.add(value: properties, for: subsequentSibling)
                subsequentSiblingEntitiesTree.set(value: subtree, for: firstSibling)
            }
        }
    }
    
    // MARK: - Interface
    
    func match(entity: CSSEntity, ancestors: [CSSEntity] = [], previousSiblings: [CSSEntity] = []) -> Properties {
        var results = entitiesTree.match(entity: entity)
        if let parent = ancestors.last {
            let childCombinatorTrees = childEntitiesTree.match(entity: parent)
            
            let properties = childCombinatorTrees.map({ $0.value }).flatMap({ $0.match(entity: entity) })
            results.append(contentsOf: properties)
        }
        
        for ancestor in ancestors {
            let descendantCombinatorTrees = descendantEntitiesTree.match(entity: ancestor)
            
            let properties = descendantCombinatorTrees.map({ $0.value }).flatMap({ $0.match(entity: entity) })
            results.append(contentsOf: properties)
        }
        
        if let previousSibling = previousSiblings.last {
            let nextSiblingCombinatorTrees = nextSiblingEntitiesTree.match(entity: previousSibling)
            
            let properties = nextSiblingCombinatorTrees.map({ $0.value }).flatMap({ $0.match(entity: entity) })
            results.append(contentsOf: properties)
        }
        
        for sibling in previousSiblings {
            let subsequentSiblingsCombinatorTrees = subsequentSiblingEntitiesTree.match(entity: sibling)
            
            let properties = subsequentSiblingsCombinatorTrees.map({ $0.value }).flatMap({ $0.match(entity: entity) })
            results.append(contentsOf: properties)
        }
        
        let sorted = results.sorted(by: { $0.specifity < $1.specifity }).map({ $0.value })
        return sorted.reduce(Properties()) { partialResult, newDict in
            return partialResult.merging(newDict, uniquingKeysWith: { _, last in last })
        }
    }
}

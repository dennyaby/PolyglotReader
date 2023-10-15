//
//  CSSTree.swift
//  MyReader
//
//  Created by  Dennya on 15/10/2023.
//

import Foundation

struct CSSTree<PropertyType> {
    
    // MARK: - Nested Types
    
    enum ElementKey: Hashable {
        case any
        case element(HTMLElement)
        
        init(element: HTMLElement?) {
            if let element = element {
                self = .element(element)
            } else {
                self = .any
            }
        }
    }
    
    enum IDKey: Hashable {
        case any
        case id(String)
        
        init(id: String?) {
            if let id = id {
                self = .id(id)
            } else {
                self = .any
            }
        }
    }
    
    enum ClassesKey: Hashable {
        case any
        case classes(Set<String>)
        
        init(classes: Set<String>) {
            if classes.isEmpty {
                self = .any
            } else {
                self = .classes(classes)
            }
        }
    }
    
    struct MatchResultItem {
        let value: PropertyType
        let specifity: CSSSpecifity
    }
    
    // MARK: - Properties
    
    var dict: [ElementKey: [ClassesKey: [IDKey: PropertyType]]]
    
    // MARK: - Init
    
    init(dict: [ElementKey : [ClassesKey : [IDKey : PropertyType]]] = [:]) {
        self.dict = dict
    }
    
    // MARK: - Interface
    
    mutating func set(value: PropertyType?, for entity: CSSEntity) {
        set(value: value, to: .init(element: entity.element), classes: .init(classes: entity.classes), id: .init(id: entity.id))
    }

    mutating func set(value: PropertyType?, to element: ElementKey, classes: ClassesKey, id: IDKey) {
        if dict[element] == nil {
            dict[element] = [:]
        }
        
        if dict[element]?[classes] == nil {
            dict[element]?[classes] = [:]
        }
        
        dict[element]?[classes]?[id] = value
    }
    
    func value(for entity: CSSEntity) -> PropertyType? {
        return dict[.init(element: entity.element)]?[.init(classes: entity.classes)]?[.init(id: entity.id)]
    }
    
    // MARK: - Matching
    
    func match(entity: CSSEntity) -> [MatchResultItem] {
        var result: [MatchResultItem] = []
        
        var elementKeys: [ElementKey] = [.any]
        if let element = entity.element {
            elementKeys.append(.element(element))
        }
        
        var idKeys: [IDKey] = [.any]
        if let id = entity.id {
            idKeys.append(.id(id))
        }
        
        for elementKey in elementKeys {
            let classesToUse = dict[elementKey]?.filter({ key, _ in
                switch key {
                case .any: return true
                case .classes(let classes): return classes.isSubset(of: entity.classes)
                }
            }) ?? [:]
            
            for classKey in classesToUse.keys {
                for idKey in idKeys {
                    if let value = classesToUse[classKey]?[idKey] {
                        result.append(.init(value: value, specifity: specifity(for: elementKey, classes: classKey, id: idKey)))
                    }
                }
            }
        }
        return result
    }
    
    // MARK: - Helper
    
    private func specifity(for elementKey: ElementKey, classes classesKey: ClassesKey, id idKey: IDKey) -> CSSSpecifity {
        let element: Int
        let classes: Int
        let id: Int
        
        switch elementKey {
        case .any: element = 0
        case .element(_): element = 1
        }
        
        switch classesKey {
        case .any: classes = 0
        case .classes(let c): classes = c.count
        }
        
        switch idKey {
        case .any: id = 0
        case .id(_): id = 1
        }
        return CSSSpecifity(element: element, classes: classes, id: id)
    }
}

extension CSSTree where PropertyType == CSSParser.Properties {
    
    mutating func add(value: PropertyType, for entity: CSSEntity) {
        var current = self.value(for: entity) ?? [:]
        let new = current.merging(value, uniquingKeysWith: { _, last in last })
        set(value: new, for: entity)
    }
}

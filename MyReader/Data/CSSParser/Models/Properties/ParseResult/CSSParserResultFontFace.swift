//
//  CSSParserResultFontFace.swift
//  MyReader
//
//  Created by  Dennya on 23/10/2023.
//

import Foundation

extension CSSParserResult {
    struct FontFace: Hashable {
        
        // MARK: - Nested Types
        
        struct Source {
            enum SourceType {
                case local
                case url
            }
            
            let sourceType: SourceType
            let path: String
        }
        
        // MARK: - Properties
        
        let family: CSSFontFamily
        let src: [Source]
        let weight: CSSFontWeight?
        let maxWeight: CSSFontWeight?
        let fontStyle: CSSFontStyle?
        
        var weightRange: ClosedRange<Int>?
        
        // MARK: - Init
        
        init?(from: [CSSProperty: String]) {
            guard let familyProperty = from[.fontFamily], let family = CSSFontFamily(string: familyProperty, useGlobalValue: false) else {
                return nil
            }
            
            guard let srcProperty = from[.src] else {
                return nil
            }
            
            let src = Self.src(from: srcProperty)
            guard src.count > 0 else {
                return nil
            }
            
            self.family = family
            self.src = src
            
            let weightProperty = from[.fontWeight] ?? ""
            (self.weight, self.maxWeight, self.weightRange) = Self.fontWeights(from: weightProperty)
            
            if let styleProperty = from[.fontStyle] {
                self.fontStyle = CSSFontStyle(string: styleProperty.trimmingCharacters(in: .whitespacesAndNewlines), useGlobalValue: true)
            } else {
                self.fontStyle = nil
            }
        }
        
        // MARK: - Equatable
        
        static func == (lhs: CSSParserResult.FontFace, rhs: CSSParserResult.FontFace) -> Bool {
            return lhs.family == rhs.family && lhs.weightRange == rhs.weightRange && lhs.fontStyle == rhs.fontStyle
        }
        
        // MARK: - Hashable
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(family)
            hasher.combine(weightRange)
            hasher.combine(fontStyle)
        }
        
        // MARK: - Helper
        
        private static func src(from string: String) -> [Source] {
            var result: [Source] = []
            for src in string.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines)}) {
                let srcComponents = src.components(separatedBy: " ").filter({ $0.isEmpty == false })
                for component in srcComponents {
                    if component.starts(with: "url(") {
                        let path = component
                            .replacingOccurrences(of: "url(", with: "")
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: "\"", with: "")
                        result.append(.init(sourceType: .url, path: path))
                        break
                    } else if component.starts(with: "local(") {
                        let path = component
                            .replacingOccurrences(of: "local(", with: "")
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: "\"", with: "")
                        result.append(.init(sourceType: .local, path: path))
                        break
                    }
                }
            }
            return result
        }
        
        private static func fontWeights(from string: String) -> (CSSFontWeight?, CSSFontWeight?, ClosedRange<Int>?) {
            let weights = string.components(separatedBy: " ").filter({ $0.isEmpty == false })
            if weights.count == 1, let weight = CSSFontWeight(string: weights[0], useGlobalValue: false) {
                switch weight {
                case .specific(let value):
                    return (weight, nil, value...value)
                default:
                    break
                }
            } else if weights.count == 2, let minWeight = CSSFontWeight(string: weights[0], useGlobalValue: false),
                      let maxWeight = CSSFontWeight(string: weights[1], useGlobalValue: false){
                switch (minWeight, maxWeight) {
                case (.specific(let minValue), .specific(let maxValue)):
                    return (minWeight, maxWeight, minValue...maxValue)
                default:
                    break
                }
            }
            return (nil, nil, nil)
        }
    }
}

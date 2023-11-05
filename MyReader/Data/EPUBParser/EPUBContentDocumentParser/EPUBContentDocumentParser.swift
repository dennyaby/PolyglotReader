//
//  EPUBContentDocumentParser.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import Foundation
import UIKit.UIColor

final class EPUBContentDocumentParser: NSObject, XMLParserDelegate {
    
    // MARK: - Nested Types
    
    private struct BuildDocumentResult {
        fileprivate struct Element {
            let element: DocumentResult.Element
            let requestNewLine: Bool
        }
        
        let elements: [Element]
        let requestNewLine: Bool
    }
    
    // MARK: - Properties
    
    private let htmlParser = HTMLParser()
    private let cssParser = CSSParser()
    private var style: CSSParserResult?
    
    private let attributesManager = AttributesManager()
    
    static let baseCSSUrl = Bundle.main.url(forResource: "base", withExtension: "css")
    
    // MARK: - Interface
    
    func parse(url: URL) -> DocumentResult? {
        guard let component = htmlParser.parse(url: url) else {
            return nil
        }
        
        style = nil
        
        let buildDocumentResultElements = buildDocumentResult(from: component, url: url)
        let elements = convertToDocumentElement(buildDocumentResultElements.elements)
        return DocumentResult(elements: elements, fontFaces: style?.fontFaces ?? [])
    }
    
    // MARK: - Logic
    
    private func buildDocumentResult(from component: HTMLComponent, url: URL, attributes: DocumentResult.Element.Attributes = .init(), ancestors: [CSSEntity] = [], previousSiblings: [CSSEntity] = [], requestNewLine rnl: Bool = false) -> BuildDocumentResult {
        switch component {
        case .text(let text):
            if text != "" {
                return BuildDocumentResult(elements: [.init(element: .init(elementType: .text(text), attributes: attributes), requestNewLine: rnl)], requestNewLine: false)
            } else {
                return BuildDocumentResult(elements: [], requestNewLine: rnl)
            }
        case .element(let element):
            guard element.name != .head else {
                style = loadResourcesFrom(headComponents: element.components, documentUrl: url)
                return BuildDocumentResult(elements: [], requestNewLine: false)
            }
            
            var requestNewLine = rnl
            let newAttributes = attributesManager.apply(htmlAttributes: element.attributes, css: style, to: element, ancestors: ancestors, previousSiblings: previousSiblings, currentAttributes: attributes)
            
            let isBlock = (newAttributes.display ?? .block) == .block
            if isBlock {
                requestNewLine = true
            }
            
            var result: [BuildDocumentResult.Element] = []
            if element.name == .img, let src = element.attributes["src"] {
                result.append(.init(element: .init(elementType: .image(src), attributes: newAttributes), requestNewLine: requestNewLine))
            }
            
            var previousSiblings: [CSSEntity] = []
            let ancestors = ancestors + [element.cssEntity]
            for component in element.components {
                let componentResult = buildDocumentResult(from: component, url: url, attributes: newAttributes, ancestors: ancestors, previousSiblings: previousSiblings, requestNewLine: requestNewLine)
                result.append(contentsOf: componentResult.elements)
                requestNewLine = componentResult.requestNewLine
                
                if case .element(let element) = component {
                    previousSiblings.append(element.cssEntity)
                }
            }
            
            return BuildDocumentResult(elements: result, requestNewLine: isBlock || requestNewLine)
        }
    }
    
    private func loadResourcesFrom(headComponents: [HTMLComponent], documentUrl: URL) -> CSSParserResult? {
        var styleURLs = [Self.baseCSSUrl].compactMap({ $0 })
        for component in headComponents {
            guard case .element(let element) = component else {
                continue
            }
            switch element.name {
            case .link:
                guard let rel = element.attributes["rel"],
                      let href = element.attributes["href"],
                      let typeString = element.attributes["type"],
                      let type = HTMLElementType(from: typeString) else {
                    continue
                }
                switch rel {
                case "stylesheet":
                    guard type == .textCss else {
                        continue
                    }
                    
                    guard let fileUrl = URLResolver.resolveResource(path: href, linkedFrom: documentUrl) else { continue }
                    styleURLs.append(fileUrl)
                default:
                    print("\(rel) relationship is not handled")
                    
                }
            default:
                break
            }
        }
        return parseStyles(urls: styleURLs)
    }
    
    private func parseStyles(urls: [URL]) -> CSSParserResult? {
        guard urls.count > 0 else {
            return nil
        }
        
        let filesContent = urls.compactMap { url -> String? in
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
        
        guard filesContent.count > 0 else {
            return nil
        }
        
        let oneBigFile = filesContent.joined(separator: "\n")
        return cssParser.parse(string: oneBigFile, baseUrl: urls.last!) // TODO: urls.last is bad idea, it will break custom font faces for second and next style files
    }
    
    private func convertToDocumentElement(_ buildResult: [BuildDocumentResult.Element]) -> [DocumentResult.Element] {
        var result = buildResult.map({ $0.element })
        for index in 0..<buildResult.count - 1 {
            if buildResult[index + 1].requestNewLine {
                if case .text(let text) = result[index].elementType {
                    result[index].elementType = .text(text + "\n")
                }
            }
        }
        return result
    }
}

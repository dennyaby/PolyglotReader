//
//  CSSParserTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 05/10/2023.
//

import XCTest
@testable import MyReader

final class CSSParserTests: XCTestCase {
    
    // MARK: - Tests
    
    func testSimpleParse() {
        let url = simpleCSSFileUrl()!

        let parser = CSSParser()
        let result = parser.parse(url: url)!
        
        let bodyCss = result.match(element: .body)

        XCTAssertEqual(bodyCss[.width], "100px")
        XCTAssertEqual(bodyCss[.textAlign], "center")

        let someidCss = result.match(element: .div, id: "someid")
        XCTAssertEqual(someidCss[.textAlign], "left")
    }

    func testComplexSelectors() {
        let url = complexSelectorsCSSFileUrl()!

        let parser = CSSParser()

        guard let result = parser.parse(url: url) else {
            XCTFail("Parsed failed to parse file")
            return
        }

        XCTAssertEqual(result.match(element: .p)[.width], "50px")
        
        XCTAssertEqual(result.match(element: .a, classes: ["class1"])[.width], "100px")

        XCTAssertEqual(result.match(element: .body, id: "id1")[.width], "150px")

        XCTAssertEqual(result.match(element: .body, classes: ["class1"])[.width], "200px")

        XCTAssertEqual(result.match(element: .div, classes: ["class1", "class2"])[.width], "250px")

        XCTAssertEqual(result.match(element: .body, classes: ["class3", "class4", "class5"])[.width], "300px")

        XCTAssertEqual(result.match(element: .body, classes: ["class1", "class2"], id: "id2")[.width], "350px")

        XCTAssertEqual(result.match(element: .a, id: "id5")[.width], "400px")

        XCTAssertEqual(result.match(element: .div, classes: ["class1", "class3"], id: "someotherid")[.width], "450px")
    }
    
    func testGroupCombinators() {
        let url = combinatorSelectorsCSSFileUrl()!

        let parser = CSSParser()
        let result = parser.parse(url: url)!
        
        XCTAssertEqual(result.match(element: .h1)[.width], "50px")
        XCTAssertEqual(result.match(element: .h2)[.width], "50px")
        XCTAssertEqual(result.match(element: .h3)[.width], "50px")
        
        XCTAssertEqual(result.match(classes: ["class1"])[.width], "100px")
        XCTAssertEqual(result.match(id: "id1")[.width], "100px")
        XCTAssertEqual(result.match(element: .h6)[.width], "100px")
    }
    
    func testChildCombinators() {
        let url = combinatorSelectorsCSSFileUrl()!

        let parser = CSSParser()
        let result = parser.parse(url: url)!
        
        let match1 = result.match(entity: .init(element: .a), ancestors: [.init(element: .div)], previousSiblings: [])
        XCTAssertEqual(match1[.width], "150px")
        XCTAssertNil(result.match(element: .a)[.width])
        
        let match2 = result.match(entity: .init(element: .p, id: "id8"), ancestors: [.init(classes: ["class3", "class1"], id: "id5")], previousSiblings: [])
        XCTAssertEqual(match2[.width], "200px")
        
        let match3 = result.match(entity: .init(element: .p, id: "id8"), ancestors: [.init(id: "id5")], previousSiblings: [])
        XCTAssertNil(match3[.width])
        
        let match4 = result.match(entity: .init(element: .p, id: "id8"), ancestors: [.init(classes: ["class3", "class1"], id: "id5"), .init(element: .div)], previousSiblings: [])
        XCTAssertNil(match4[.width])
    }
    
    func testNextSiblingCombinators() {
        let url = combinatorSelectorsCSSFileUrl()!

        let parser = CSSParser()
        let result = parser.parse(url: url)!

        let match1 = result.match(entity: .init(id: "id11"), ancestors: [], previousSiblings: [.init(id: "id10")])
        XCTAssertEqual(match1[.width], "250px")
        XCTAssertNil(result.match(id: "id11")[.width])
        
        let match2 = result.match(entity: .init(element: .p), ancestors: [], previousSiblings: [.init(classes: ["class7"], id: "id10")])
        XCTAssertEqual(match2[.width], "300px")
        
        let match3 = result.match(entity: .init(id: "id11"), ancestors: [], previousSiblings: [.init(id: "id10"), .init(id: "id12")])
        XCTAssertNil(match3[.width])
        
        let match4 = result.match(entity: .init(id: "id11"), ancestors: [], previousSiblings: [.init(id: "id10"), .init(id: "id12")])
        XCTAssertNil(match4[.width])
    }
    
    func testSubsequentSiblingCombinators() {
        let url = combinatorSelectorsCSSFileUrl()!

        let parser = CSSParser()
        let result = parser.parse(url: url)!

        let match1 = result.match(entity: .init(element: .a), ancestors: [], previousSiblings: [.init(element: .p), .init(element: .span)])
        XCTAssertEqual(match1[.width], "350px")
        XCTAssertNil(result.match(element: .a)[.width])
        
        let match2 = result.match(entity: .init(element: .code), ancestors: [], previousSiblings: [.init(element: .p), .init(element: .span), .init(element: .a)])
        XCTAssertNil(match2[.width])
        
        let match3 = result.match(entity: .init(element: .p), ancestors: [], previousSiblings: [.init(element: .span, classes: ["header"])])
        XCTAssertEqual(match3[.width], "400px")
    }
    
    func testDescendantCombinators() {
        let url = combinatorSelectorsCSSFileUrl()!

        let parser = CSSParser()
        let result = parser.parse(url: url)!

        let match1 = result.match(entity: .init(element: .span), ancestors: [.init(element: .div), .init(element: .p)], previousSiblings: [])
        XCTAssertEqual(match1[.width], "450px")
        XCTAssertNil(result.match(element: .span)[.width])
        
        let match2 = result.match(entity: .init(element: .a), ancestors: [.init(classes: ["footer"])], previousSiblings: [])
        XCTAssertEqual(match2[.width], "500px")
    }
    
    // MARK: - Helper
    
    private func simpleCSSFileUrl() -> URL? {
        return Bundle.test?.url(forResource: "simple", withExtension: "css")
    }
    
    private func complexSelectorsCSSFileUrl() -> URL? {
        return Bundle.test?.url(forResource: "complex_selectors", withExtension: "css")
    }
    
    private func combinatorSelectorsCSSFileUrl() -> URL? {
        return Bundle.test?.url(forResource: "combinator_selectors", withExtension: "css")
    }
}

fileprivate extension CSSParserResult {
    func match(element: HTMLElement? = nil, classes: Set<String> = [], id: String? = nil) -> Properties {
        return match(entity: .init(element: element, classes: classes, id: id))
    }
}

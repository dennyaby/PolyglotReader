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
    
    // MARK: - Helper
    
    private func simpleCSSFileUrl() -> URL? {
        return Bundle.test?.url(forResource: "simple", withExtension: "css")
    }
    
    private func complexSelectorsCSSFileUrl() -> URL? {
        return Bundle.test?.url(forResource: "complex_selectors", withExtension: "css")
    }
}

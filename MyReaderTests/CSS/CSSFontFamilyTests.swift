//
//  CSSFontFamilyTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 11/10/2023.
//

import XCTest
@testable import MyReader

final class CSSFontFamilyTests: XCTestCase {

    func testGlobalValues() {
        XCTAssertEqual(CSSFontFamily(string: "initial"), .global(.initial))
        XCTAssertEqual(CSSFontFamily(string: "unset"), .global(.unset))
    }
    
    func testGenericFamilies() {
        XCTAssertEqual(CSSFontFamily(string: "serif"), .families([.generic(.serif)]))
        XCTAssertEqual(CSSFontFamily(string: "monospace, cursive, sans-serif"), .families([.generic(.monospace), .generic(.cursive), .generic(.sansSerif)]))
    }
    
    func testSpecificFamilies() {
        XCTAssertEqual(CSSFontFamily(string: "\"MyFont\""), .families([.specific("MyFont")]))
        XCTAssertEqual(CSSFontFamily(string: "\"Gill Sans Extrabold\", \"Goudy Bookletter 1911\""), .families([.specific("Gill Sans Extrabold"), .specific("Goudy Bookletter 1911")]))
    }
    
    func testMixedFamilies() {
        XCTAssertEqual(CSSFontFamily(string: "monospace, \"MyFont\", serif, \"Gothica\""), .families([.generic(.monospace), .specific("MyFont"), .generic(.serif), .specific("Gothica")]))
    }

}

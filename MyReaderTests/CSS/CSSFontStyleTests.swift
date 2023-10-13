//
//  CSSFontStyleTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 11/10/2023.
//

import XCTest
@testable import MyReader

final class CSSFontStyleTests: XCTestCase {

    func testGlobalValues() {
        XCTAssertEqual(CSSFontStyle(string: "inherit"), .global(.inherit))
        XCTAssertEqual(CSSFontStyle(string: "initial"), .global(.initial))
    }
    
    func testStyleValues() {
        XCTAssertEqual(CSSFontStyle(string: "Normal"), .style(.normal))
        XCTAssertEqual(CSSFontStyle(string: "italic"), .style(.italic))
        XCTAssertEqual(CSSFontStyle(string: "oblique"), .style(.oblique))
    }

    func testInvalidValues() {
        XCTAssertNil(CSSFontStyle(string: "normales"))
        XCTAssertNil(CSSFontStyle(string: "15"))
    }

}

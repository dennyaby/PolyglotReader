//
//  CSSFontWeightTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 11/10/2023.
//

import XCTest
@testable import MyReader

final class CSSFontWeightTests: XCTestCase {

    func testGlobalValues() {
        XCTAssertEqual(CSSFontWeight(string: "initial"), .global(.initial))
        XCTAssertEqual(CSSFontWeight(string: "revert"), .global(.revert))
    }
    
    func testRelativeValues() {
        XCTAssertEqual(CSSFontWeight(string: "Bolder"), .relative(.bolder))
        XCTAssertEqual(CSSFontWeight(string: "lighter"), .relative(.lighter))
    }
    
    func testSpecificValues() {
        XCTAssertEqual(CSSFontWeight(string: "bold"), .specific(CSSFontWeight.bold))
        XCTAssertEqual(CSSFontWeight(string: "normal"), .specific(CSSFontWeight.normal))
        XCTAssertEqual(CSSFontWeight(string: "950"), .specific(950))
        XCTAssertEqual(CSSFontWeight(string: "1500"), .specific(1000))
        XCTAssertEqual(CSSFontWeight(string: "-500"), .specific(1))
    }
    
    func testInvalidValues() {
        XCTAssertNil(CSSFontWeight(string: "blabla"))
    }
}

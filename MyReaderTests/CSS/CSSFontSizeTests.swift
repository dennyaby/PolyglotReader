//
//  CSSFontSizeTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 11/10/2023.
//

import XCTest
@testable import MyReader

final class CSSFontSizeTests: XCTestCase {
    
    func testGlobalValues() {
        XCTAssertEqual(CSSFontSize(string: "initial"), .global(.initial))
        XCTAssertEqual(CSSFontSize(string: "revert"), .global(.revert))
    }
    
    func testRelativeValues() {
        XCTAssertEqual(CSSFontSize(string: "Larger"), .relative(.larger))
        XCTAssertEqual(CSSFontSize(string: "smaller"), .relative(.smaller))
    }
    
    func testAbsoluteValues() {
        XCTAssertEqual(CSSFontSize(string: "xx-small"), .absolute(.xxSmall))
        XCTAssertEqual(CSSFontSize(string: "large"), .absolute(.large))
        XCTAssertEqual(CSSFontSize(string: "Xxx-large"), .absolute(.xxxLarge))
    }
    
    func testNumericValues() {
        XCTAssertEqual(CSSFontSize(string: "25pt"), .numeric(.pt(25)))
        XCTAssertEqual(CSSFontSize(string: "1.2em"), .numeric(.em(1.2)))
        XCTAssertEqual(CSSFontSize(string: "20px"), .numeric(.px(20)))
    }
    
    func testPercentValues() {
        XCTAssertEqual(CSSFontSize(string: "250%"), .percent(250))
        XCTAssertEqual(CSSFontSize(string: "11.5%"), .percent(11.5))
    }
    
    func testInvalidValues() {
        XCTAssertNil(CSSFontSize(string: "blabla"))
        XCTAssertNil(CSSFontSize(string: "50%%"))
    }
}

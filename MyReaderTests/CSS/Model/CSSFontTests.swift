//
//  CSSFontTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 12/10/2023.
//

import XCTest
@testable import MyReader

final class CSSFontTests: XCTestCase {


    func testFontStyleAttribute() {
        let font1 = CSSFont(string: "italic")
        XCTAssertNil(font1.fontFamily)
        XCTAssertNil(font1.fontSize)
        XCTAssertNil(font1.fontWeight)
        XCTAssertEqual(font1.fontStyle, .style(.italic))
        
        let font2 = CSSFont(string: "normal")
        XCTAssertNil(font2.fontFamily)
        XCTAssertNil(font2.fontSize)
        XCTAssertNil(font2.fontWeight)
        XCTAssertEqual(font2.fontStyle, .style(.normal))
    }

    func testFontWeightAttribute() {
        let font1 = CSSFont(string: "bold")
        XCTAssertNil(font1.fontFamily)
        XCTAssertNil(font1.fontSize)
        XCTAssertNil(font1.fontStyle)
        XCTAssertEqual(font1.fontWeight, .specific(CSSFontWeight.bold))
    }
    
    func testFontSizeAttribute() {
        let font1 = CSSFont(string: "1.5em")
        XCTAssertNil(font1.fontFamily)
        XCTAssertNil(font1.fontStyle)
        XCTAssertNil(font1.fontWeight)
        XCTAssertEqual(font1.fontSize, .numeric(.em(1.5)))
        
        let font2 = CSSFont(string: "small")
        XCTAssertNil(font2.fontFamily)
        XCTAssertNil(font2.fontStyle)
        XCTAssertNil(font2.fontWeight)
        XCTAssertEqual(font2.fontSize, .absolute(.small))
    }
    
    func testFontFamilyAttribute() {
        let font1 = CSSFont(string: "serif")
        XCTAssertNil(font1.fontStyle)
        XCTAssertNil(font1.fontWeight)
        XCTAssertNil(font1.fontSize)
        XCTAssertEqual(font1.fontFamily, .families([.generic(.serif)]))
        
        let font2 = CSSFont(string: "serif, \"Font1\", \"Font 35\", monospace")
        XCTAssertNil(font2.fontStyle)
        XCTAssertNil(font2.fontWeight)
        XCTAssertNil(font2.fontSize)
        XCTAssertEqual(font2.fontFamily, .families([.generic(.serif), .specific("Font1"), .specific("Font 35"), .generic(.monospace)]))
    }
    
    func testMixedAttributes() {
        let font1 = CSSFont(string: "1.2em \"Fira Sans\", sans-serif")
        XCTAssertNil(font1.fontStyle)
        XCTAssertNil(font1.fontWeight)
        XCTAssertEqual(font1.fontSize, .numeric(.em(1.2)))
        XCTAssertEqual(font1.fontFamily, .families([.specific("Fira Sans"), .generic(.sansSerif)]))
        
        let font2 = CSSFont(string: "italic bold 1.2em \"Fira Sans\", sans-serif")
        XCTAssertEqual(font2.fontStyle, .style(.italic))
        XCTAssertEqual(font2.fontWeight, .specific(CSSFontWeight.bold))
        XCTAssertEqual(font2.fontSize, .numeric(.em(1.2)))
        XCTAssertEqual(font2.fontFamily, .families([.specific("Fira Sans"), .generic(.sansSerif)]))
    }

}

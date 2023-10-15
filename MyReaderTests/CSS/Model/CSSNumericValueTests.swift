//
//  CSSNumericValueTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 08/10/2023.
//

import XCTest
@testable import MyReader

final class CSSNumericValueTests: XCTestCase {

    func testNumericValues() {
        guard let emValue = CSSNumericValue(string: "5em") else {
            XCTFail("Unable to init from string '5em'")
            return
        }
        XCTAssertEqual(emValue, .em(5))
        
        guard let ptValue = CSSNumericValue(string: "12.5pt") else {
            XCTFail("Unable to init from string '12.5pt'")
            return
        }
        XCTAssertEqual(ptValue, .pt(12.5))
        
        guard let pxValue = CSSNumericValue(string: ".5px") else {
            XCTFail("Unable to init from string '.5px'")
            return
        }
        XCTAssertEqual(pxValue, .px(0.5))
        
        guard let zero = CSSNumericValue(string: "0") else {
            XCTFail("Unable to init from string '0'")
            return
        }
        XCTAssertEqual(zero, .px(0))
        
        XCTAssertNil(CSSNumericValue(string: "asf"))
        XCTAssertNil(CSSNumericValue(string: "15pxem"))
    }
}

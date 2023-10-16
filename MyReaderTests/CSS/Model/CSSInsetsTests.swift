//
//  CSSInsetsTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 17/10/2023.
//

import XCTest
@testable import MyReader

final class CSSInsetsTests: XCTestCase {
    
    func testCSSInsets() {
        XCTAssertNil(CSSInsets(from: ""))
        
        let insets1 = CSSInsets(from: "5px")
        XCTAssertEqual(insets1?.top, .px(5))
        XCTAssertEqual(insets1?.bottom, .px(5))
        XCTAssertEqual(insets1?.right, .px(5))
        XCTAssertEqual(insets1?.left, .px(5))
        
        let insets2 = CSSInsets(from: "10% auto")
        XCTAssertEqual(insets2?.top, .percent(10))
        XCTAssertEqual(insets2?.bottom, .percent(10))
        XCTAssertEqual(insets2?.right, .zero)
        XCTAssertEqual(insets2?.left, .zero)
        
        let insets3 = CSSInsets(from: "1em 2em 3em")
        XCTAssertEqual(insets3?.top, .em(1))
        XCTAssertEqual(insets3?.bottom, .em(3))
        XCTAssertEqual(insets3?.right, .em(2))
        XCTAssertEqual(insets3?.left, .em(2))
        
        let insets4 = CSSInsets(from: "5px 1em 0 2em")
        XCTAssertEqual(insets4?.top, .px(5))
        XCTAssertEqual(insets4?.bottom, .zero)
        XCTAssertEqual(insets4?.right, .em(1))
        XCTAssertEqual(insets4?.left, .em(2))
    }
}

//
//  CSSTextAlignTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 07/10/2023.
//

import XCTest
@testable import MyReader

final class CSSTextAlignTests: XCTestCase {

    func testCSSTextAlign() throws {
        XCTAssertEqual(CSSTextAlign(from: "start")?.textAlign, .left)
        XCTAssertEqual(CSSTextAlign(from: "end")?.textAlign, .right)
        XCTAssertEqual(CSSTextAlign(from: "center")?.textAlign, .center)
        XCTAssertEqual(CSSTextAlign(from: "justify")?.textAlign, .justified)
        XCTAssertNil(CSSTextAlign(from: "not_valid"))
    }
}

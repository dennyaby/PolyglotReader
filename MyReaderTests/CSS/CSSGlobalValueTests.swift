//
//  CSSGlobalValueTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 11/10/2023.
//

import XCTest
@testable import MyReader

final class CSSGlobalValueTests: XCTestCase {
    
    func testGlobalValues() {
        XCTAssertEqual(CSSGlobalValue(rawValue: "inherit"), .inherit)
        XCTAssertEqual(CSSGlobalValue(rawValue: "initial"), .initial)
        XCTAssertEqual(CSSGlobalValue(rawValue: "revert"), .revert)
        XCTAssertEqual(CSSGlobalValue(rawValue: "revert-layer"), .revertLayer)
        XCTAssertEqual(CSSGlobalValue(rawValue: "unset"), .unset)
    }
}

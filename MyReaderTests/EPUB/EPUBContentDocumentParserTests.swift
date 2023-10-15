//
//  EPUBContentDocumentParserTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 15/10/2023.
//

import XCTest
@testable import MyReader

final class EPUBContentDocumentParserTests: XCTestCase {
    
    func testHtml1Text() {
        guard let url = urlFor(htmlWith: "html1") else {
            XCTFail("No ulr for 'html1'")
            return
        }
        
        guard let elements = EPUBContentDocumentParser().parse(url: url)?.elements else {
            XCTFail("Parse error")
            return
        }
        XCTAssertEqual(elements.count, 1)
        
        XCTAssertEqual(constructString(from: elements), "Test1")
    }
    
    func testHtml2Text() {
        guard let url = urlFor(htmlWith: "html2") else {
            XCTFail("No ulr for 'html2'")
            return
        }
        
        guard let elements = EPUBContentDocumentParser().parse(url: url)?.elements else {
            XCTFail("Parse error")
            return
        }
        XCTAssertEqual(elements.count, 2)
        
        XCTAssertEqual(constructString(from: elements), "Test1\nTest2")
    }
    
    func testHtml3Text() {
        guard let url = urlFor(htmlWith: "html3") else {
            XCTFail("No ulr for 'html3'")
            return
        }
        
        guard let elements = EPUBContentDocumentParser().parse(url: url)?.elements else {
            XCTFail("Parse error")
            return
        }
        XCTAssertEqual(elements.count, 3)
        
        XCTAssertEqual(constructString(from: elements), "Test1Test2\nTest3")
    }
    
    func testHtml4Text() {
        guard let url = urlFor(htmlWith: "html4") else {
            XCTFail("No ulr for 'html4'")
            return
        }
        
        guard let elements = EPUBContentDocumentParser().parse(url: url)?.elements else {
            XCTFail("Parse error")
            return
        }
        XCTAssertEqual(elements.count, 3)
        
        XCTAssertEqual(constructString(from: elements), "Test1Test2\nTest3")
    }
    
    func testHtml5Text() {
        guard let url = urlFor(htmlWith: "html5") else {
            XCTFail("No ulr for 'html5'")
            return
        }
        
        guard let elements = EPUBContentDocumentParser().parse(url: url)?.elements else {
            XCTFail("Parse error")
            return
        }
        XCTAssertEqual(elements.count, 9)
        
        XCTAssertEqual(constructString(from: elements), "Test1Test2Test3\nTest4\nTest5\nTest6\nTest7\nTest8\nTest9")
    }
    
    // MARK: - Helper
    
    private func constructString(from elements: [EPUBContentDocumentParser.DocumentResult.Element]) -> String {
        var result = ""
        for element in elements {
            switch element.elementType {
            case .image(let name):
                result.append("image[\(name)]")
            case .text(let text):
                result.append(text)
            }
        }
        return result
    }
    
    private func urlFor(htmlWith name: String) -> URL? {
        return Bundle.test?.url(forResource: name, withExtension: "html")
    }
    
}

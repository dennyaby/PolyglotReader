//
//  HTMLParserTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 15/10/2023.
//

import XCTest
@testable import MyReader

final class HTMLParserTests: XCTestCase {
    
    // MARK: - Test Cases
    
    func testHtml1HeadParse() {
        guard let url = urlFor(htmlWith: "html1") else {
            XCTFail("Unable to obtain url")
            return
        }
        
        guard let component = HTMLParser().parse(url: url) else {
            XCTFail("Unable to parse")
            return
        }
        
        switch component {
        case .text(_):
            XCTFail("Should be element")
            return
        case .element(let element):
            XCTAssertEqual(element.name, .html)
            XCTAssertEqual(element.attributes.count, 3)
            
            guard element.components.count == 2 else {
                XCTFail("Element should have exactly 2 components")
                return
            }
            
            
            let head = element.components[0]

            
            switch head {
            case .text(_):
                XCTFail("Should be element")
                return
            case .element(let element):
                XCTAssertEqual(element.name, .head)
                XCTAssertEqual(element.attributes.count, 0)
                
                guard element.components.count == 1 else {
                    XCTFail("Element should have exactly 1 component")
                    return
                }
                
                let title = element.components[0]
                switch title {
                case .text(_):
                    XCTFail("Should be element")
                    return
                case .element(let element):
                    XCTAssertEqual(element.name, .title)
                    XCTAssertEqual(element.attributes.count, 0)
                    
                    guard element.components.count == 1 else {
                        XCTFail("Element should have exactly 1 component")
                        return
                    }
                    
                    let titleText = element.components[0]
                    switch titleText {
                    case .element(_):
                        XCTFail("Should be test")
                        return
                    case .text(let text):
                        XCTAssertEqual(text, "No mater")
                    }
                }
            }
        }
    }

    // MARK: - Helper
    
    private func urlFor(htmlWith name: String) -> URL? {
        return Bundle.test?.url(forResource: name, withExtension: "html")
    }
    
}

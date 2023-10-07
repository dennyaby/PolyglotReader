//
//  CSSColorTests.swift
//  MyReaderTests
//
//  Created by  Dennya on 07/10/2023.
//

import XCTest
@testable import MyReader

final class CSSColorTests: XCTestCase {
    
    // MARK: - Tests
    
    func testColorByName() {
        guard let blanchedAlmond = CSSColor(from: "BlanchedAlmond") else {
            XCTFail("Unable init CSSColor from 'BlanchedAlmond'")
            return
        }
        XCTAssertTrue(isColorsIdentical(blanchedAlmond.uiColor, UIColor(red: 1, green: 0.92, blue: 0.8, alpha: 1)))
        
        guard let darkRed = CSSColor(from: "DarkRed") else {
            XCTFail("Unable init CSSColor from 'DarkRed'")
            return
        }
        XCTAssertTrue(isColorsIdentical(darkRed.uiColor, UIColor(red: 0.55, green: 0, blue: 0, alpha: 1)))
        
        guard let paleTurquoise = CSSColor(from: "PaleTurquoise") else {
            XCTFail("Unable init CSSColor from 'PaleTurquiose'")
            return
        }
        XCTAssertTrue(isColorsIdentical(paleTurquoise.uiColor, UIColor(red: 0.69, green: 0.93, blue: 0.93, alpha: 1)))
        
        
        XCTAssertFalse(isColorsIdentical(blanchedAlmond.uiColor, darkRed.uiColor))
        XCTAssertFalse(isColorsIdentical(darkRed.uiColor, paleTurquoise.uiColor))
    }
    
    func testColorByRGB() {
        guard let color1 = CSSColor(from: "rgb(255, 255, 255)") else {
            XCTFail("Unable to init CSSColor from 'rgb(255, 255, 255)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color1.uiColor, .init(red: 1, green: 1, blue: 1, alpha: 1)))
        
        guard let color2 = CSSColor(from: "rgb(0, 127, 255)") else {
            XCTFail("Unable to init CSSColor from 'rgb(0, 127, 255)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color2.uiColor, .init(red: 0, green: 0.5, blue: 1, alpha: 1)))
        
        guard let color3 = CSSColor(from: "rgb(165, 42, 42)") else {
            XCTFail("Unable to init CSSColor from 'rgb(165, 42, 42)'")
            return
        }
        
        guard let color4 = CSSColor(from: "Brown") else {
            XCTFail("Unable to init CSSColor from 'Brown'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color3.uiColor, color4.uiColor))
    }
    
    func testColorByRGBA() {
        guard let color1 = CSSColor(from: "rgba(255, 255, 255, 1)") else {
            XCTFail("Unable to init CSSColor from 'rgba(255, 255, 255, 1)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color1.uiColor, .init(red: 1, green: 1, blue: 1, alpha: 1)))
        
        guard let color2 = CSSColor(from: "rgba(0, 127, 255, 0.5)") else {
            XCTFail("Unable to init CSSColor from 'rgba(0, 127, 255, 0.5)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color2.uiColor, .init(red: 0, green: 0.5, blue: 1, alpha: 0.5)))
        
        guard let color3 = CSSColor(from: "rgba(165, 42, 42, 0.5)") else {
            XCTFail("Unable to init CSSColor from 'rgba(165, 42, 42, 0.5)'")
            return
        }
        
        guard let color4 = CSSColor(from: "Brown") else {
            XCTFail("Unable to init CSSColor from 'Brown'")
            return
        }
        XCTAssertFalse(isColorsIdentical(color3.uiColor, color4.uiColor))
    }
    
    func testColorByHEX() {
        guard let color1 = CSSColor(from: "#ffffff") else {
            XCTFail("Unable to init CSSColor from '#ffffff'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color1.uiColor, UIColor(red: 1, green: 1, blue: 1, alpha: 1)))
        XCTAssertFalse(isColorsIdentical(color1.uiColor, UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)))
        
        guard let color2 = CSSColor(from: "#dda0dd") else {
            XCTFail("Unable to init CSSColor from '#dda0dd'")
            return
        }
        guard let color3 = CSSColor(from: "Plum") else {
            XCTFail("Unable to init CSSColor from 'Plum'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color2.uiColor, color3.uiColor))
        
        guard let color4 = CSSColor(from: "#3f3f3f") else {
            XCTFail("Unable to init CSSColor from '#3f3f3f'")
            return
        }
        guard let color5 = CSSColor(from: "#333333") else {
            XCTFail("Unable to init CSSColor from '#333333'")
            return
        }
        guard let color6 = CSSColor(from: "#333") else {
            XCTFail("Unable to init CSSColor from '#333'")
            return
        }
        XCTAssertFalse(isColorsIdentical(color4.uiColor, color5.uiColor))
        XCTAssertFalse(isColorsIdentical(color4.uiColor, color6.uiColor))
        XCTAssertTrue(isColorsIdentical(color5.uiColor, color6.uiColor))
    }
    
    func testColorByHSL() {
        guard let color1 = CSSColor(from: "hsl(9, 100%, 64%)") else {
            XCTFail("Unable to init CSSColor from 'hsl(9, 100%, 64%)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color1.uiColor, UIColor(hue: 0.025, saturation: 1, brightness: 0.64, alpha: 1)))
        
        guard let color2 = CSSColor(from: "hsl(200, 100%, 66%)") else {
            XCTFail("Unable to init CSSColor from 'hsl(200, 100%, 66%)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color2.uiColor, UIColor(hue: 0.555, saturation: 1, brightness: 0.66, alpha: 1)))
    }
    
    func testColorByHSLA() {
        guard let color1 = CSSColor(from: "hsla(9, 100%, 64%, 0.5)") else {
            XCTFail("Unable to init CSSColor from 'hsla(9, 100%, 64%, 0.5)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color1.uiColor, UIColor(hue: 0.025, saturation: 1, brightness: 0.64, alpha: 0.5)))
        XCTAssertFalse(isColorsIdentical(color1.uiColor, UIColor(hue: 0.025, saturation: 1, brightness: 0.64, alpha: 1)))
        
        guard let color2 = CSSColor(from: "hsla(16.11, 10%, 20%, 1)") else {
            XCTFail("Unable to init CSSColor from 'hsla(16.11, 10%, 20%, 1)'")
            return
        }
        XCTAssertTrue(isColorsIdentical(color2.uiColor, UIColor(hue: 0.045, saturation: 0.1, brightness: 0.2, alpha: 1)))
    }
    
    // MARK: - Helper
    
    private func isColorsIdentical(_ color1: UIColor, _ color2: UIColor) -> Bool {
        let rgba1 = color1.rgba
        let rgba2 = color2.rgba
        
        return [rgba1.r - rgba2.r,
                rgba1.g - rgba2.g,
                rgba1.b - rgba2.b,
                rgba1.a - rgba2.a].map({ abs($0) }).contains(where: { $0 > 0.01 }) == false

    }
}

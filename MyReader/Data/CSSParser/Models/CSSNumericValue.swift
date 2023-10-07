//
//  CSSNumericValue.swift
//  MyReader
//
//  Created by  Dennya on 08/10/2023.
//

import Foundation
import UIKit.UIScreen

enum CSSNumericValue: Hashable {
    
    case px(CGFloat)
    case em(CGFloat)
    case pt(CGFloat)
    
    // MARK: - Properties
    
    // MARK: - Init
    
    init?(string: String?) {
        guard let string = string else {
            return nil
        }
        switch string.suffix(2) {
        case "em":
            if let emValue = Double(string.dropLast(2)) {
                self = .em(CGFloat(emValue))
            } else {
                return nil
            }
        case "px":
            if let pxValue = Double(string.dropLast(2)) {
                self = .px(CGFloat(pxValue))
            } else {
                return nil
            }
        case "pt":
            if let ptValue = Double(string.dropLast(2)) {
                self = .pt(CGFloat(ptValue))
            } else {
                return nil
            }
        default:
            if let doubleValue = Double(string) {
                self = .px(CGFloat(doubleValue))
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Interface
    
    func pointSize(with fontSize: CGFloat) -> CGFloat {
        switch self {
        case .pt(let pt): return pt
        case .px(let px): return px / UIScreen.main.scale // TODO: Check if it is safe to call it from background thread
        case .em(let em): return fontSize * em
        }
    }
    
    // MARK: - Operators
    
    static func *(lhs: CSSNumericValue, rhs: CGFloat) -> CSSNumericValue {
        switch lhs {
        case .em(let em): return .em(em * rhs)
        case .px(let px): return .px(px * rhs)
        case .pt(let pt): return .pt(pt * rhs)
        }
    }
    
    static func /(lhs: CSSNumericValue, rhs: CGFloat) -> CSSNumericValue {
        switch lhs {
        case .em(let em): return .em(em / rhs)
        case .px(let px): return .px(px / rhs)
        case .pt(let pt): return .pt(pt / rhs)
        }
    }
}

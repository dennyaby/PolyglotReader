//
//  String+Range.swift
//  MyReader
//
//  Created by  Dennya on 20/11/2023.
//

import Foundation

extension String {
    func getIntRange(from range: Range<String.Index>) -> Range<Int> {
        return distance(from: startIndex, to: range.lowerBound)..<distance(from: startIndex, to: range.upperBound)
    }
    
    func getNSRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(location: distance(from: startIndex, to: range.lowerBound), length: distance(from: range.lowerBound, to: range.upperBound))
    }
}

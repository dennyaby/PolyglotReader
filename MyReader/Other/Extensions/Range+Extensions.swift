//
//  NSRange+Intersection.swift
//  MyReader
//
//  Created by  Dennya on 21/11/2023.
//

import Foundation

extension NSRange {
    func intersection(with range: NSRange) -> NSRange? {
        let x1 = location
        let x2 = location + length
        
        let y1 = range.location
        let y2 = range.location + range.length
        
        guard y2 > x1 && y1 < x2 else {
            return nil
        }
        
        let z1 = max(x1, y1)
        let z2 = min(x2, y2)
        
        guard z2 > z1 else {
            return nil
        }
        
        return NSRange(location: z1, length: z2 - z1)
    }
}

extension CFRange {
    var nsRange: NSRange {
        return .init(location: location, length: length)
    }
}

//
//  Word.swift
//  MyReader
//
//  Created by  Dennya on 10/12/2023.
//

import Foundation

extension CoreTextFrameManager {
    struct Word: Equatable, Comparable, Hashable {
        let range: NSRange
        let frames: [CGRect]
        
        static func <(lhs: Word, rhs: Word) -> Bool {
            return lhs.range.location < rhs.range.location
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(range)
        }
    }
}

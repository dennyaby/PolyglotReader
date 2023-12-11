//
//  Line.swift
//  MyReader
//
//  Created by  Dennya on 10/12/2023.
//

import Foundation

extension CoreTextFrameManager {
    struct Line {
        struct LineFrame {
            let word: Word
            let frameIndex: Int
            var frame: CGRect {
                return word.frames[frameIndex]
            }
        }
        let frame: CGRect
        let lineFrames: [LineFrame]
        
        func isPointInCurrentLine(point: CGPoint) -> Bool {
            return point.y >= frame.origin.y && point.y <= frame.maxY
        }
        
        func matchWord(at point: CGPoint) -> Word? {
            guard lineFrames.count > 0 else { return nil }
            
            if let pointInsideWord = lineFrames.first(where: { $0.frame.contains(point) }) {
                return pointInsideWord.word
            }
            let distances = lineFrames.map { abs($0.frame.midX - point.x) - $0.frame.width / 2 }
            var minDistanceIndex = 0
            
            for index in 1..<distances.count {
                if distances[index] < distances[minDistanceIndex] {
                    minDistanceIndex = index
                }
            }
            return lineFrames[minDistanceIndex].word
        }
    }
}

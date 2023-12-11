//
//  DocumentInfo.swift
//  MyReader
//
//  Created by  Dennya on 10/12/2023.
//

import Foundation

extension CoreTextFrameManager {
    struct DocumentInfo {
        let lines: [Line]
        let maxY: CGFloat
        let minY: CGFloat
        
        func match(point: CGPoint, calculateOutsideTheLines: Bool) -> Word? {
            guard lines.count > 0 else { return nil }
            let line: Line
            if point.y < minY {
                if calculateOutsideTheLines {
                    line = lines[0]
                } else {
                    return nil
                }
            } else if point.y > maxY {
                if calculateOutsideTheLines {
                    line = lines.last!
                } else {
                    return nil
                }
            } else {
                var minDistance: CGFloat = .greatestFiniteMagnitude
                var lineToUse: Line?
                for line in lines {
                    if line.isPointInCurrentLine(point: point) {
                        lineToUse = line
                        break
                    } else {
                        let distance = abs(point.y - line.frame.midY) - line.frame.height / 2
                        if distance < minDistance {
                            lineToUse = line
                            minDistance = distance
                        }
                    }
                }
                if let lineToUse = lineToUse {
                    line = lineToUse
                } else {
                    return nil
                }
            }
            return line.matchWord(at: point)
        }
    }
}

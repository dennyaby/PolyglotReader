//
//  CoreTextFrameManager.swift
//  MyReader
//
//  Created by  Dennya on 09/11/2023.
//

import CoreText
import UIKit
import NaturalLanguage

final class CoreTextFrameManager {
    
    // MARK: - Properties
    
    private lazy var documentInfo = calculateDocumentInfo()
    private lazy var allWords = calculateAllWords()
    private var selectionCache: [Word: [Word: Selection]] = [:]
    
    // MARK: - Properties
    
    let ctFrame: CTFrame
    let string: NSAttributedString
    let viewSize: CGSize
    
    // MARK: - Init
    
    init(ctFrame: CTFrame, string: NSAttributedString, viewSize: CGSize) {
        self.ctFrame = ctFrame
        self.string = string
        self.viewSize = viewSize
    }
    
    // MARK: - Interface
    
    func getWord(for touchPoint: CGPoint) -> Word? {
        return documentInfo?.match(point: touchPoint, calculateOutsideTheLines: false)
    }
    
    func getSelection(for point1: CGPoint, point2: CGPoint) -> Selection? {
        let words = getClosestWords(for: [point1, point2]).compactMap({ $0 }).sorted()
        if words.count == 0 {
            return nil
        } else if words.count == 1 || words[0] == words[1] {
            let word = words[0]
            return .init(firstWord: word, lastWord: nil, range: word.range, frames: word.frames)
        }
        
        let firstWord = words[0]
        let lastWord = words[1]
        
        if let cached = selectionCache[firstWord]?[lastWord] {
            return cached
        }
        
        guard let firstWordIndex = allWords.firstIndex(of: firstWord), let secondWordInex = allWords.firstIndex(of: lastWord) else { return nil }
        
        let rangeLength = lastWord.range.location + lastWord.range.length - firstWord.range.location
        let textRange = NSRange(location: firstWord.range.location, length: rangeLength)
        
        var resultFrames: [CGRect] = []
        var lineFrames: [CGRect] = [firstWord.frames[0]]
        var lineMidY: CGFloat = firstWord.frames[0].midY
        
        for frame in allWords[firstWordIndex...secondWordInex].flatMap({ $0.frames }).dropFirst() {
            if frame.origin.y > lineMidY || frame.maxY < lineMidY {
                resultFrames.append(combine(lineFrames: lineFrames))
                lineFrames = [frame]
                lineMidY = frame.midY
                continue
            }
            lineFrames.append(frame)
        }
        resultFrames.append(combine(lineFrames: lineFrames))
        let result = Selection(firstWord: firstWord, lastWord: lastWord, range: textRange, frames: resultFrames)
        var firstWordDict = selectionCache[firstWord] ?? [:]
        firstWordDict[lastWord] = result
        selectionCache[firstWord] = firstWordDict
        
        return result
    }
    
    // MARK: - Private
    
    private func combine(lineFrames: [CGRect]) -> CGRect {
        let firstFrameOrigin = lineFrames.first!.origin
        
        let lastFrame = lineFrames.last!
        let lastFrameBottomRight = CGPoint(x: lastFrame.maxX, y: lastFrame.maxY)
        
        return CGRect(origin: firstFrameOrigin, size: CGSize(width: lastFrameBottomRight.x - firstFrameOrigin.x, height: lastFrameBottomRight.y - firstFrameOrigin.y))
    }
    
    private func getClosestWords(for points: [CGPoint]) -> [Word?] {
        var result = [Word?](repeating: nil, count: points.count)
        
        for index in 0..<points.count {
            result[index] = documentInfo?.match(point: points[index], calculateOutsideTheLines: true)
        }
        return result
    }
    
    private func calculateDocumentInfo() -> DocumentInfo? {
        let lines = (CTFrameGetLines(ctFrame) as? [CTLine]) ?? []
        guard lines.count > 0 else { return nil }
        
        let textNSRange = CTFrameGetVisibleStringRange(ctFrame).nsRange
        
        let text = self.string.string
        guard let textRange = Range(textNSRange, in: text) else { return nil }
        
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), &origins)
        origins = origins.map { CGPoint(x: $0.x, y: viewSize.height - $0.y) }
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        var currentLineIndex = 0
        var lineBounds: [Int: CGRect] = [:]
        
        var allWords: [Word] = []
        var lineIndexToInfo: [Int: [(Int, Int)]] = [:]
        
        tokenizer.enumerateTokens(in: textRange) { range, _ in
            let wordRange = text.getNSRange(from: range)
            var frames: [CGRect] = []
            for lineIndex in currentLineIndex..<lines.count {
                currentLineIndex = lineIndex
                let line = lines[lineIndex]
                
                let lineRange = CTLineGetStringRange(line).nsRange
                
                guard let intersection = wordRange.intersection(lineRange), intersection.length > 0 else {
                    continue
                }
                
                let leadingX = CTLineGetOffsetForStringIndex(line, intersection.location, nil)
                let trailingX = CTLineGetOffsetForStringIndex(line, intersection.location + intersection.length, nil)
                
                let bounds: CGRect
                if let existing = lineBounds[lineIndex] {
                    bounds = existing
                } else {
                    bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions())
                    lineBounds[lineIndex] = bounds
                }
                
                var lineOrigin = origins[lineIndex]
                let height = bounds.height
                lineOrigin.y -= height + bounds.origin.y
                
                let frame = CGRect(x: lineOrigin.x + leadingX, y: lineOrigin.y, width: trailingX - leadingX, height: height)
                frames.append(frame)
                var currentLineInfo = lineIndexToInfo[lineIndex] ?? []
                currentLineInfo.append((allWords.count, frames.count - 1))
                lineIndexToInfo[lineIndex] = currentLineInfo
                
                if wordRange.location + wordRange.length > lineRange.location + lineRange.length {
                    continue
                } else {
                    break
                }
            }
            if frames.count > 0 {
                allWords.append(.init(range: wordRange, frames: frames))
            }
            return true
        }
        
        let resultLines = lineIndexToInfo.sorted(by: { $0.key < $1.key }).compactMap { keyValuePair -> Line? in
            let lineIndex = keyValuePair.key
            let lineInfo = keyValuePair.value
            guard var bounds = lineBounds[lineIndex] else { return nil }
            var lineOrigin = origins[lineIndex]
            lineOrigin.y -= bounds.height + bounds.origin.y
            bounds.origin = lineOrigin
            var lineFrames: [Line.LineFrame] = []
            for info in lineInfo {
                lineFrames.append(.init(word: allWords[info.0], frameIndex: info.1))
            }
            return .init(frame: bounds, lineFrames: lineFrames)
        }
        
        guard resultLines.count > 0 else { return nil }
        let docMinY = resultLines.first!.frame.origin.y
        let docMaxY = resultLines.last!.frame.maxY
        
        return .init(lines: resultLines, maxY: docMaxY, minY: docMinY)
    }
    
    private func calculateAllWords() -> [Word] {
        guard let documentInfo = documentInfo else { return [] }
        let allWords = documentInfo.lines.flatMap { $0.lineFrames.map { $0.word } }
        return Set(allWords).sorted()
    }
    
    private func calculateWords() -> [Word] {
        var result: [Word] = []
        
        let lines = (CTFrameGetLines(ctFrame) as? [CTLine]) ?? []
        guard lines.count > 0 else { return [] }
        
        let textNSRange = CTFrameGetVisibleStringRange(ctFrame).nsRange
        
        let text = self.string.string
        guard let textRange = Range(textNSRange, in: text) else { return [] }
        
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), &origins)
        origins = origins.map { CGPoint(x: $0.x, y: viewSize.height - $0.y) }
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        var currentLineIndex = 0
        var lineBounds: [CTLine: CGRect] = [:]
        
        tokenizer.enumerateTokens(in: textRange) { range, _ in
            let wordRange = text.getNSRange(from: range)
            var frames: [CGRect] = []
            for lineIndex in currentLineIndex..<lines.count {
                currentLineIndex = lineIndex
                let line = lines[lineIndex]
                
                let lineRange = CTLineGetStringRange(line).nsRange
                
                guard let intersection = wordRange.intersection(lineRange), intersection.length > 0 else {
                    continue
                }
                
                let leadingX = CTLineGetOffsetForStringIndex(line, intersection.location, nil)
                let trailingX = CTLineGetOffsetForStringIndex(line, intersection.location + intersection.length, nil)
                
                let bounds: CGRect
                if let existing = lineBounds[line] {
                    bounds = existing
                } else {
                    bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions())
                    lineBounds[line] = bounds
                }
                
                var lineOrigin = origins[lineIndex]
                let height = bounds.height
                lineOrigin.y -= height + bounds.origin.y
                
                let frame = CGRect(x: lineOrigin.x + leadingX, y: lineOrigin.y, width: trailingX - leadingX, height: height)
                frames.append(frame)
                
                if wordRange.location + wordRange.length > lineRange.location + lineRange.length {
                    continue
                } else {
                    break
                }
            }
            if frames.count > 0 {
                result.append(.init(range: wordRange, frames: frames))
            }
            return true
        }
        
        return result
    }
}

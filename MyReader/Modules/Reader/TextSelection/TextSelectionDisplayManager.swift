//
//  TextSelectionDisplayManager.swift
//  MyReader
//
//  Created by  Dennya on 18/11/2023.
//

import UIKit

final class TextSelectionDisplayManager {
    
    // MARK: - Nested Types
    
    struct Config {
        let selectionColor: UIColor
        var backgroundColor: UIColor {
            return selectionColor.withAlphaComponent(0.2)
        }
        
        let movePointSize: CGFloat
        let moveBorderWidth: CGFloat
        
        static let standard: Config = .init(selectionColor: .systemBlue, movePointSize: 10, moveBorderWidth: 2)
    }
    
    struct DisplayResult {
        let firstPoint: CGPoint
        let secondPoint: CGPoint
        let displayFrames: [CGRect]
    }
    
    // MARK: - Properties
    
    private let collectionView: UICollectionView
    private let config: Config
    private var layers: [CALayer] = []
    
    // MARK: - Init
    
    init(collectionView: UICollectionView, config: Config = .standard) {
        self.collectionView = collectionView
        self.config = config
    }
    
    // MARK: - Interface
    
    func clearSelection() {
        layers.forEach { $0.removeFromSuperlayer() }
        layers = []
    }
    
    func displaySelection(frames: [CGRect]) -> DisplayResult? {
        clearSelection()
        guard frames.count > 0 else { return nil }
        let frames = joinFramesIfCloseLocated(frames: frames)
        for frame in frames {
            let layer = CALayer()
            layer.backgroundColor = config.backgroundColor.cgColor
            layer.frame = frame
            collectionView.layer.addSublayer(layer)
            layers.append(layer)
        }
        
        let (firstLayer, firstPoint) = moveBorderLayer(wordFrame: frames.first!, isFirst: true)
        let (secondLayer, secondPoint) = moveBorderLayer(wordFrame: frames.last!, isFirst: false)
        
        [firstLayer, secondLayer].forEach { layer in
            collectionView.layer.addSublayer(layer)
            layers.append(layer)
        }
        return .init(firstPoint: firstPoint, secondPoint: secondPoint, displayFrames: frames)
    }
    
    // MARK: - Helper
    
    private func moveBorderLayer(wordFrame: CGRect, isFirst: Bool) -> (CALayer, CGPoint) {
        let layer = CALayer()
        let line = moveBorderLineLayer(height: wordFrame.height)
        layer.addSublayer(line)
        
        let point = moveBorderPointLayer()
        layer.addSublayer(point)
        
        let layerX: CGFloat
        let layerY: CGFloat
        let lineY: CGFloat
        let pointY: CGFloat
        
        if isFirst {
            layerX = wordFrame.origin.x - line.bounds.width / 2 - point.bounds.width / 2
            layerY = wordFrame.origin.y - point.bounds.height
            lineY = point.bounds.height
            pointY = 0
        } else {
            layerX = wordFrame.maxX + line.bounds.width / 2 - point.bounds.width / 2
            layerY = wordFrame.origin.y
            lineY = 0
            pointY = line.bounds.height
        }
        
        layer.frame = CGRect(x: layerX, y: layerY, width: point.bounds.width, height: point.bounds.height + line.bounds.height)
        line.frame.origin = CGPoint(x: layer.bounds.width / 2 - line.bounds.width / 2, y: lineY)
        let pointOrigin = CGPoint(x: 0, y: pointY)
        point.frame.origin = pointOrigin
        let pointCenter = CGPoint(x: pointOrigin.x + point.bounds.width / 2, y: pointOrigin.y + point.bounds.height / 2)
        
        return (layer, layer.frame.origin + pointCenter)
    }
    
    private func moveBorderPointLayer() -> CALayer {
        let layer = CALayer()
        layer.backgroundColor = config.selectionColor.cgColor
        layer.bounds.size = CGSize(width: config.movePointSize, height: config.movePointSize)
        layer.cornerRadius = config.movePointSize / 2
        return layer
    }
    
    private func moveBorderLineLayer(height: CGFloat) -> CALayer {
        let layer = CALayer()
        layer.backgroundColor = config.selectionColor.cgColor
        layer.bounds.size = CGSize(width: config.moveBorderWidth, height: height)
        return layer
    }
    
    private func joinFramesIfCloseLocated(frames: [CGRect]) -> [CGRect] {
        guard frames.count > 0 else { return [] }
        var result: [CGRect] = [frames[0]]
        
        for frame in frames.dropFirst() {
            let deltaY = frame.origin.y - result.last!.maxY
            if deltaY > 0 && deltaY <= 2 {
                result.append(.init(origin: .init(x: frame.origin.x, y: frame.origin.y - deltaY), size: .init(width: frame.size.width, height: frame.size.height + deltaY)))
            } else {
                result.append(frame)
            }
        }
        return result
    }
}

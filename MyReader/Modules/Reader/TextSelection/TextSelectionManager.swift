//
//  TextSelectionManager.swift
//  MyReader
//
//  Created by  Dennya on 09/11/2023.
//

import CoreText
import UIKit

protocol TextSelectionManagerDelegate: AnyObject {
    func textSelectionManagerDidSelect(_ manager: TextSelectionManager, selectionInfo: TextSelectionInfo)
    func textSelectionManagerDidDeselect(_ manager: TextSelectionManager)
    func textSelectionManagerIsSelecting(_ manager: TextSelectionManager, selectionInfo: TextSelectionInfo)
}

final class TextSelectionManager {
    
    private struct SelectedWord {
        let frames: [CGRect]
    }
    
    // MARK: - Properties
    
    private let textSelectionGR = TextSelectionGestureRecognizer()
    private let textPanGR = SpecificAreasRestrictedPanGestureRecognizer()
    private let tapGR = UITapGestureRecognizer()
    private let textSelectionDisplayManager: TextSelectionDisplayManager
    private let collectionView: UICollectionView
    private var viewSize: CGSize {
        return collectionView.bounds.size - textInsets
    }
    
    private var firstSelectedWord: SelectedWord?
    private var lastSelectedWord: SelectedWord?

    private var selectionState: SelectionState?
    
    private var pillarLocation: CGPoint?
    private var adjustStartLocation: CGPoint?
    
    private var ctFrame: CTFrame?
    private var coreTextFrameManagers: [CTFrame: CoreTextFrameManager] = [:]
    
    private(set) var isSelected = false
    
    private(set) var textInsets: UIEdgeInsets = .zero
    
    weak var delegate: TextSelectionManagerDelegate?
    
    // MARK: - Init
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        self.textSelectionDisplayManager = .init(collectionView: collectionView)
        
        textSelectionGR.addTarget(self, action: #selector(textSelectionGesture))
        collectionView.addGestureRecognizer(textSelectionGR)
        
        textPanGR.addTarget(self, action: #selector(textPanGesture))
        collectionView.addGestureRecognizer(textPanGR)
        
        collectionView.panGestureRecognizer.require(toFail: textPanGR)
        textPanGR.require(toFail: textSelectionGR)
        
        collectionView.panGestureRecognizer.addTarget(self, action: #selector(collectionViewPanGesture))
        
        tapGR.addTarget(self, action: #selector(tapGesture))
        collectionView.addGestureRecognizer(tapGR)
    }
    
    // MARK: - Interface
    
    func set(ctFrame: CTFrame?, string: NSAttributedString) {
        self.ctFrame = ctFrame
        if let ctFrame = ctFrame {
            coreTextFrameManagers[ctFrame] = .init(ctFrame: ctFrame, string: string, viewSize: viewSize)
        }
    }
    
    func set(textInsets: UIEdgeInsets) {
        self.textInsets = textInsets
        resetCache()
    }
    
    func resetCache() {
        coreTextFrameManagers = [:]
    }
    
    // MARK: - Gestures
    
    @objc private func textSelectionGesture(gr: TextSelectionGestureRecognizer) {
        switch gr.state {
        case .began:
            displaySelection(point: gr.location(in: collectionView))
            isSelected = true
            
            if let selectionState = selectionState {
                delegate?.textSelectionManagerDidSelect(self, selectionInfo: selectionState.textSelectionInfo)
            }
        default:
            break
        }
    }
    
    @objc private func textPanGesture(gr: SpecificAreasRestrictedPanGestureRecognizer) {
        switch gr.state {
        case .changed:
            if let pillarLocation = pillarLocation, let adjustStartLocation = adjustStartLocation {
                let adjustLocation = adjustStartLocation + gr.panOffset
                displayTwoPointSelection(point1: pillarLocation, point2: adjustLocation)
                
                if let selectionState = selectionState {
                    delegate?.textSelectionManagerIsSelecting(self, selectionInfo: selectionState.textSelectionInfo)
                }
            } else {
                guard let displayResult = selectionState?.displayResult, let firstSelectedWord = firstSelectedWord else { return }
                
                let isFirstPointTouched = gr.gestureArea?.center == displayResult.firstPoint
                
                let pillarWord: SelectedWord
                if isFirstPointTouched {
                    if let lastSelectedWord = lastSelectedWord {
                        pillarWord = lastSelectedWord
                    } else {
                        pillarWord = firstSelectedWord
                    }
                } else {
                    pillarWord = firstSelectedWord
                }
                guard pillarWord.frames.count > 0 else { return }
                
                let pillarPoint: CGPoint
                if isFirstPointTouched {
                    pillarPoint = pillarWord.frames.first!.midPoint
                } else {
                    pillarPoint = pillarWord.frames.last!.midPoint
                }
                
                let adjustPoint: CGPoint
                if isFirstPointTouched {
                    adjustPoint = displayResult.firstPoint
                } else {
                    adjustPoint = displayResult.secondPoint
                }
                displayTwoPointSelection(point1: pillarPoint, point2: adjustPoint)
                
                self.pillarLocation = pillarPoint
                self.adjustStartLocation = adjustPoint
            }
        case .ended:
            if let selectionState = selectionState  {
                delegate?.textSelectionManagerDidSelect(self, selectionInfo: selectionState.textSelectionInfo)
            }
        case .cancelled, .failed:
            pillarLocation = nil
            adjustStartLocation = nil
        default:
            break
        }
    }
    
    @objc private func collectionViewPanGesture(gr: UIPanGestureRecognizer) {
        deselect()
    }
    
    @objc private func tapGesture(gr: UITapGestureRecognizer) {
        deselect()
    }
    
    // MARK: - Private
    
    private func deselect() {
        self.selectionState = nil
        self.isSelected = false
        textSelectionDisplayManager.clearSelection()
        
        delegate?.textSelectionManagerDidDeselect(self)
    }
    
    private func getCoreTextFrameManager() -> CoreTextFrameManager? {
        guard let ctFrame = ctFrame, let manager = coreTextFrameManagers[ctFrame] else { return nil }
        return manager
    }
    
    private func displaySelection(point: CGPoint) {
        guard let coreTextFrameManager = getCoreTextFrameManager() else { return }
        
        let touchLocation = convertPointFromCollectionViewToCTFrame(point: point)

        guard let word = coreTextFrameManager.getWord(for: touchLocation) else { return }
        let frames = word.frames.map(convertFrameFromCTFrameToCollectionView)
        firstSelectedWord = .init(frames: frames)
        lastSelectedWord = nil
        
        guard let displayResult = textSelectionDisplayManager.displaySelection(frames: frames) else { return }
        self.selectionState = .init(displayResult: displayResult, range: word.range)
        
        textPanGR.setAreas(with: [displayResult.firstPoint, displayResult.secondPoint])
    }
    
    private func displayTwoPointSelection(point1: CGPoint, point2: CGPoint) {
        guard let coreTextFrameManager = getCoreTextFrameManager() else { return }
        
        let touch1 = convertPointFromCollectionViewToCTFrame(point: point1)
        let touch2 = convertPointFromCollectionViewToCTFrame(point: point2)
        
        guard let selection = coreTextFrameManager.getSelection(for: touch1, point2: touch2) else { return }
        firstSelectedWord = .init(frames: selection.firstWord.frames.map(convertFrameFromCTFrameToCollectionView))
        if let lastWord = selection.lastWord {
            lastSelectedWord = .init(frames: lastWord.frames.map(convertFrameFromCTFrameToCollectionView))
        } else {
            lastSelectedWord = nil
        }
        
        guard let displayResult = textSelectionDisplayManager.displaySelection(frames: selection.frames.map(convertFrameFromCTFrameToCollectionView)) else { return }
        self.selectionState = .init(displayResult: displayResult, range: selection.range)
        
        textPanGR.setAreas(with: [displayResult.firstPoint, displayResult.secondPoint])
    }
    
    private func convertPointFromCollectionViewToCTFrame(point: CGPoint) -> CGPoint {
        let touchDeltaX = collectionView.contentOffset.x + textInsets.left
        let touchDeltaY = collectionView.contentOffset.y + textInsets.top
        let touchLocationX = point.x - touchDeltaX
        let touchLocationY = point.y - touchDeltaY
        return CGPoint(x: touchLocationX, y: touchLocationY)
    }
    
    private func convertFrameFromCTFrameToCollectionView(frame: CGRect) -> CGRect {
        let touchDeltaX = collectionView.contentOffset.x + textInsets.left
        let touchDeltaY = collectionView.contentOffset.y + textInsets.top
        let deltaPoint = CGPoint(x: touchDeltaX, y: touchDeltaY)
        return CGRect(origin: frame.origin + deltaPoint, size: frame.size)
    }
}

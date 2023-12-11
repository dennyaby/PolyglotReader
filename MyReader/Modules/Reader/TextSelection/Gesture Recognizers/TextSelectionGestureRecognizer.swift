//
//  TextSelectionGestureRecognizer.swift
//  MyReader
//
//  Created by  Dennya on 08/11/2023.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

final class TextSelectionGestureRecognizer: UIGestureRecognizer {
    
    // MARK: - Constants
    
    private static let longPressDuration: TimeInterval = 0.5
    private static let longPressSuccessfullRecognitionRadius: CGFloat = 20
    
    // MARK: - Properties
    
    private(set) var startLocation: CGPoint?
    private(set) var currentLocation: CGPoint?
    
    private var trackedTouch: UITouch?
    
    private var longPressTimer: Timer?
    
    // MARK: - Overrides
    
    override func reset() {
        super.reset()
        self.startLocation = nil
        self.currentLocation = nil
        self.trackedTouch = nil
        self.longPressTimer?.invalidate()
        self.longPressTimer = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 1 else {
            self.state = .failed
            return
        }
        
        self.trackedTouch = touches.first
        self.startLocation = trackedTouch?.location(in: view)
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.longPressDuration, repeats: false, block: { [weak self] timer in
            guard let self else { return }
            self.state = .changed
        })
        state = .possible
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard self.state != .failed else { return }
        
        guard touches.count == 1, touches.first == trackedTouch else {
            self.state = .failed
            return
        }
        
        let touch = trackedTouch!
        let location = touch.location(in: view)
        self.currentLocation = location
        
        switch state {
        case .changed:
            self.state = .changed
        case .possible:
            guard let startLocation = startLocation else {
                self.state = .failed
                return
            }
            
            if startLocation.distance(to: location) > Self.longPressSuccessfullRecognitionRadius {
                self.state = .failed
            }
        default:
            self.state = .failed
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.first == trackedTouch {
            self.currentLocation = trackedTouch?.location(in: view)
        }
        self.state = .ended
    }
}

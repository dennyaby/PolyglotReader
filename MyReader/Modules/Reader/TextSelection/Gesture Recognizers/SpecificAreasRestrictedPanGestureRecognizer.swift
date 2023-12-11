//
//  SpecificAreasRestrictedPanGestureRecognizer.swift
//  MyReader
//
//  Created by  Dennya on 26/11/2023.
//

import UIKit

final class SpecificAreasRestrictedPanGestureRecognizer: UIGestureRecognizer {
    
    // MARK: - Constants
    
    static let defaultRadius: CGFloat = 10
    
    // MARK: - Nested Types
    
    struct Area: Equatable {
        let center: CGPoint
        let radius: CGFloat
    }
    
    // MARK: - Properties
    
    var areas: [Area] = []
    private(set) var gestureArea: Area?
    private var startGestureLocation: CGPoint = .zero
    private(set) var panOffset: CGPoint = .zero
    
    // MARK: - Interface
    
    func setAreas(with centers: [CGPoint], radius: CGFloat = SpecificAreasRestrictedPanGestureRecognizer.defaultRadius) {
        self.areas = centers.map { .init(center: $0, radius: radius) }
    }
    
    // MARK: - UIGestureRecognizer Methods
    
    override func reset() {
        super.reset()
        gestureArea = nil
        panOffset = .zero
        startGestureLocation = .zero
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 1, areas.count > 0 else {
            self.state = .failed
            return
        }
        
        let touch = touches.first!
        let location = touch.location(in: view)
        
        
        let validAreas = areas.filter { $0.center.distance(to: location) <= $0.radius }
        
        guard validAreas.count > 0 else {
            self.state = .failed
            return
        }
        
        panOffset = .zero
        startGestureLocation = location
        
        let area = validAreas.min(by: { $0.center.distance(to: location) < $1.center.distance(to: location) })!
        self.gestureArea = area
        
        state = .changed
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard self.state != .failed else { return }
        
        guard touches.count == 1 else {
            self.state = .failed
            return
        }
        
        let location = touches.first!.location(in: view)
        panOffset = CGPoint(x: location.x - startGestureLocation.x, y: location.y - startGestureLocation.y)
        state = .changed
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }
}

//
//  CGPoint+Extensions.swift
//  MyReader
//
//  Created by  Dennya on 08/11/2023.
//

import UIKit

extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        let dx = x - to.x
        let dy = y - to.y
        return sqrt(dx * dx + dy * dy)
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

extension CGRect {
    static func +(lhs: CGRect, rhs: CGPoint) -> CGRect {
        return .init(origin: lhs.origin + rhs, size: lhs.size)
    }
}

extension CGSize {
    static func -(lhs: CGSize, rhs: UIEdgeInsets) -> CGSize {
        return .init(width: lhs.width - rhs.left - rhs.right, height: lhs.height - rhs.top - rhs.bottom)
    }
}

extension CGRect {
    var bottomRightPoint: CGPoint {
        return .init(x: maxX, y: maxY)
    }
    
    var midPoint: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

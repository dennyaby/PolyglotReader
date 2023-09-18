//
//  NSConstraintInArray.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import UIKit

extension Array where Element == NSLayoutConstraint {
    func activate() {
        forEach { $0.isActive = true }
    }
}

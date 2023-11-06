//
//  BookHighlight.swift
//  MyReader
//
//  Created by  Dennya on 06/11/2023.
//

import Foundation
import UIKit.UIColor

struct BookHighlight {
    
    // MARK: - Properties
    
    let id: Storage.ID
    let startLocation: BookLocation
    let length: Int
    let color: String?
    
    // MARK: - Init
    
    init(id: Storage.ID, startLocation: BookLocation, length: Int, color: String?) {
        self.id = id
        self.startLocation = startLocation
        self.length = length
        self.color = color
    }
    
    init(id: Storage.ID, startLocation: BookLocation, length: Int, color: UIColor?) {
        self.init(id: id, startLocation: startLocation, length: length, color: color?.stringRepresentation())
    }
    
    // MARK: - Interface
    
    func getHighlightColor() -> UIColor? {
        guard let color = color else { return nil }
        return UIColor(stringRepresentation: color)
    }
}

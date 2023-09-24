//
//  ReaderCollectionViewCell.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import UIKit
import CoreText

final class ReaderCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var ctFrame: CTFrame?
    var leadingSpacing: CGFloat = 0
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView Methods
    
    override func draw(_ rect: CGRect) {
        guard let ctFrame = ctFrame, let context = UIGraphicsGetCurrentContext() else { return }
        
        context.textMatrix = .identity
        context.translateBy(x: leadingSpacing, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        CTFrameDraw(ctFrame, context)
        
        print("Draw call")
    }
    
    
}

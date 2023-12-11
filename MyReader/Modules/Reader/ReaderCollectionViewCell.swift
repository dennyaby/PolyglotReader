//
//  ReaderCollectionViewCell.swift
//  MyReader
//
//  Created by  Dennya on 22/09/2023.
//

import UIKit
import CoreText

protocol ReaderCollectionViewCellDelegate: AnyObject {
    func getImagesToDrawForReaderCollectionViewCell(_ cell: ReaderCollectionViewCell) -> [ReaderCollectionViewCell.ImageInfo]
}

final class ReaderCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Nested Types
    
    struct ImageInfo {
        let image: UIImage
        let frame: CGRect
    }
    
    // MARK: - Properties
    
    var ctFrame: CTFrame?
    var leadingSpacing: CGFloat = 0
    var topSpacing: CGFloat = 0
    
    weak var delegate: ReaderCollectionViewCellDelegate?
    
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
        context.translateBy(x: leadingSpacing, y: bounds.size.height - topSpacing)
        context.scaleBy(x: 1.0, y: -1.0)

        CTFrameDraw(ctFrame, context)
        
        for imageInfo in delegate?.getImagesToDrawForReaderCollectionViewCell(self) ?? [] {
            guard let cgImage = imageInfo.image.cgImage else { continue }
            context.draw(cgImage, in: imageInfo.frame)
        }
    }
    
    
}

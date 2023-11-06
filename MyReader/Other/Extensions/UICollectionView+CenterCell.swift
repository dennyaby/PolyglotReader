//
//  UICollectionView+CenterCell.swift
//  MyReader
//
//  Created by  Dennya on 07/11/2023.
//

import UIKit

extension UICollectionView {
    func getCenterCellIndexPath() -> IndexPath? {
        let visibleCellsWithIndexPaths = indexPathsForVisibleItems
            .compactMap({ indexPath -> (IndexPath, UICollectionViewCell)? in
                guard let cell = cellForItem(at: indexPath) else { return nil }
                return (indexPath, cell)
            })
        
        let center = CGPoint(x: bounds.width / 2 + contentOffset.x, y: bounds.height / 2 + contentOffset.y)
        for (indexPath, cell) in visibleCellsWithIndexPaths {
            if cell.frame.contains(center) {
                return indexPath
            }
        }
        return nil
    }
}

//
//  EPUBDataProvider.swift
//  MyReader
//
//  Created by  Dennya on 18/09/2023.
//

import Foundation
import UIKit.UIColor
import UIKit

struct EPUBDataProviderConfig {
    let fontSize: CGFloat
    let textColor: UIColor
    
    static let standard = EPUBDataProviderConfig(fontSize: 20, textColor: .black)
}

struct EPUBDataProviderResult {
    let attributedString: NSAttributedString
    let documentId: String
    let images: [EPUBDataProvderImageInfo]
}

struct EPUBDataProvderImageInfo {
    let width: CGFloat
    let height: CGFloat
    let location: Int
    let url: URL
}

protocol EPUBDataProvider {
    
    init?(appManager: AppManager, book: Book, config: EPUBDataProviderConfig)
    
    func bookContents(config: EPUBDataProviderConfig, pageSize: CGSize) -> [EPUBDataProviderResult]
    func image(for url: URL) -> UIImage?
}

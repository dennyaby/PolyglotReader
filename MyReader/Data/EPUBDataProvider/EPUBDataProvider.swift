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

struct EPUBDataProviderUserSettings {
    let fontMultiplier: CGFloat
}

struct EPUBDataProviderResult {
    let attributedString: NSAttributedString
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
    
    func bookContents(userTextSettings: EPUBDataProviderUserSettings, pageSize: CGSize) -> [EPUBDataProviderResult]
    func image(for url: URL) -> UIImage?
}

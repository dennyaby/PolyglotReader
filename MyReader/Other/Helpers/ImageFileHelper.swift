//
//  ImageFileHelper.swift
//  MyReader
//
//  Created by  Dennya on 30/09/2023.
//

import Foundation
import ImageIO

struct ImageFileHelper {
    
    // MARK: - Interface
    
    static func imageSize(from url: URL) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        guard let imagePropertiesCFDict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) else {
            return nil
        }
        
        let imageProperties = imagePropertiesCFDict as NSDictionary
        

        guard var width = imageProperties[kCGImagePropertyPixelWidth] as? Int, var height = imageProperties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        
        if let imageOrientation = imageProperties[kCGImagePropertyOrientation] as? Int {
            if imageOrientation > 4 {
                width += height
                height = width - height
                width -= height
            }
        }
        
        return CGSize(width: width, height: height)
    }
}

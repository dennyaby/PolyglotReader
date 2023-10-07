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
        
        if let imageOrientation = imageProperties[kCGImagePropertyOrientation] {
            print("Image orientation: \(imageOrientation)")
        }
        
        return CGSize(width: width, height: height)
    }
}
//                Using ImageIO
//
//                NSURL *imageFileURL = [NSURL fileURLWithPath:...];
//                CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageFileURL, NULL);
//                if (imageSource == NULL) {
//                    // Error loading image
//                    ...
//                    return;
//                }
//
//                CGFloat width = 0.0f, height = 0.0f;
//                CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
//
//                CFRelease(imageSource);
//
//                if (imageProperties != NULL) {
//
//                    CFNumberRef widthNum  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
//                    if (widthNum != NULL) {
//                        CFNumberGetValue(widthNum, kCFNumberCGFloatType, &width);
//                    }
//
//                    CFNumberRef heightNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
//                    if (heightNum != NULL) {
//                        CFNumberGetValue(heightNum, kCFNumberCGFloatType, &height);
//                    }
//
//                    // Check orientation and flip size if required
//                    CFNumberRef orientationNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
//                    if (orientationNum != NULL) {
//                        int orientation;
//                        CFNumberGetValue(orientationNum, kCFNumberIntType, &orientation);
//                        if (orientation > 4) {
//                            CGFloat temp = width;
//                            width = height;
//                            height = temp;
//                        }
//                    }

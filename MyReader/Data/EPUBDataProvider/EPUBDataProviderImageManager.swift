//
//  EPUBDataProviderImageManager.swift
//  MyReader
//
//  Created by  Dennya on 05/11/2023.
//

import Foundation
import UIKit

extension EPUBDataProviderManualParse {
    final class ImageManager {
        
        // MARK: - Nested Types
        
        private struct CoreTextRunInfo {
            let ascent: CGFloat
            let descent: CGFloat
            let width: CGFloat
        }
        
        enum ImageSize {
            case ratio(CGFloat)
            case fixed(CSSNumericValue, CSSNumericValue)
        }
        
        // MARK: - Properties
        
        private var imageSizes: [URL: ImageSize] = [:]
        private let imagesCache = NSCache<NSURL, UIImage>()
        
        // MARK: - Interface
        
        func image(for url: URL) -> UIImage? {
            if let existing = imagesCache.object(forKey: url as NSURL) {
                return existing
            } else {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    imagesCache.setObject(image, forKey: url as NSURL)
                    return image
                } else {
                    print("No image with url \(url)")
                    return nil
                }
            }
        }
        
        func getLogicalImageSize(for url: URL, attributes: Attributes) -> ImageSize {
            if let existing = imageSizes[url] {
                return existing
            }
            
            let imageSize: ImageSize
            if let width = attributes.width, let height = attributes.height {
                imageSize = .fixed(width, height)
            } else if let imageFileSize = ImageFileHelper.imageSize(from: url) {
                if let width = attributes.width {
                    if imageFileSize.height != 0  {
                        let ratio = imageFileSize.width / imageFileSize.height
                        imageSize = .fixed(width, width / ratio)
                    } else {
                        imageSize = .fixed(width, width)
                    }
                } else if let height = attributes.height {
                    if imageFileSize.height != 0 {
                        let ratio = imageFileSize.width / imageFileSize.height
                        imageSize = .fixed(height * ratio, height)
                    } else {
                        imageSize = .fixed(height, height)
                    }
                } else {
                    if imageFileSize.height != 0 && imageFileSize.width != 0  {
                        imageSize = .ratio(imageFileSize.width / imageFileSize.height)
                    } else {
                        imageSize = .ratio(1)
                    }
                }
            } else {
                imageSize = .ratio(1)
            }
            imageSizes[url] = imageSize
            return imageSize
        }
        
        func getImageSize(forLogicalImageSize imageSize: ImageSize, toFitInside pageSize: CGSize, config: EPUBDataProviderConfig) -> CGSize {
            let width: CGFloat
            let height: CGFloat
            
            switch imageSize {
            case .ratio(let ratio):
                let desiredHeight = pageSize.width / ratio
                var scaleBy: CGFloat = 1
                if desiredHeight > pageSize.height {
                    scaleBy = pageSize.height / desiredHeight
                }
                width = pageSize.width * scaleBy
                height = desiredHeight * scaleBy
            case .fixed(let imageWidth, let imageHeight):
                var scaleBy: CGFloat = 1
                
                let widthInPoints = imageWidth.pointSize(with: config.fontSize)
                let heightInPoints = imageHeight.pointSize(with: config.fontSize)
                
                if widthInPoints > pageSize.width || heightInPoints > pageSize.height {
                    scaleBy = min(pageSize.width / widthInPoints, pageSize.height / heightInPoints)
                }
                
                width = widthInPoints * scaleBy
                height = heightInPoints
            }
            return CGSize(width: width, height: height)
        }
        
        func attributedStringToReprentImage(withSize imageSize: CGSize) -> NSAttributedString {
            let extentBuffer = UnsafeMutablePointer<CoreTextRunInfo>.allocate(capacity: 1)
            extentBuffer.initialize(to: CoreTextRunInfo(ascent: imageSize.height, descent: 0, width: imageSize.width))
            var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
            }, getAscent: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: CoreTextRunInfo.self)
                return d.pointee.ascent
            }, getDescent: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: CoreTextRunInfo.self)
                return d.pointee.descent
            }, getWidth: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: CoreTextRunInfo.self)
                return d.pointee.width
            })
            
            let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
            return NSAttributedString(string: "\u{FFFC}", attributes: [NSAttributedString.Key(kCTRunDelegateAttributeName as String): delegate as Any])
        }
    }
}

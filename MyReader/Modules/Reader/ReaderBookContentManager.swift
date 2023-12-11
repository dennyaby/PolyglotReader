//
//  ReaderBookContentManager.swift
//  MyReader
//
//  Created by  Dennya on 07/11/2023.
//

import CoreText
import UIKit

extension ReaderViewController {
    final class BookContentManager {
        
        struct Document {
            let id: String
            let pageFrames: [CTFrame]
            let imagesInfo: [Int: [ImageInfo]]
            let string: NSAttributedString
        }
        
        // MARK: - Properties
        
        private let epubDataProvider: EPUBDataProvider
        private let appManager: AppManager
        private var book: Book
        private var documents: [Document] = []
        
        // MARK: - Init
        
        init?(appManager: AppManager, book: Book) {
            guard let epubDataProvider = EPUBDataProviderManualParse(appManager: appManager, book: book) else {
                return nil
            }
            self.epubDataProvider = epubDataProvider
            self.appManager = appManager
            self.book = book
        }
        
        // MARK: - Interface
        
        func numberOfDocuments() -> Int {
            return documents.count
        }
        
        func numberOfPages(for documentIndex: Int) -> Int {
            return documents[documentIndex].pageFrames.count
        }
        
        func ctFrame(forDocument documentIndex: Int, page: Int) -> CTFrame {
            return documents[documentIndex].pageFrames[page]
        }
        
        func string(forDocument documentIndex: Int) -> NSAttributedString {
            return documents[documentIndex].string
        }
        
        func reloadLayout(pageSize: CGSize) {
            let content = epubDataProvider.bookContents(config: .standard, pageSize: pageSize)
            reloadBookLayout(from: content, pageSize: pageSize)
        }
        
        func getImages(for documentIndex: Int, page: Int) -> [ReaderCollectionViewCell.ImageInfo] {
            guard let imageInfo = documents[documentIndex].imagesInfo[page] else {
                return []
            }
            
            var result: [ReaderCollectionViewCell.ImageInfo] = []
            for image in imageInfo {
                guard let uiImage = epubDataProvider.image(for: image.url) else { continue }
                result.append(.init(image: uiImage, frame: image.frame))
            }
            return result
        }
        
        func saveBookLocation(documentIndex: Int, page: Int) {
            let document = documents[documentIndex]
            
            let offset = calculateCharactersOffset(for: document, page: page)
            book.location = .init(documentId: document.id, offset: offset)
            try? appManager.dataStorage.update(book: book)
        }
        
        func getCurrentDocumentAndPageIndexes() -> (document: Int, page: Int) {
            guard let location = book.location else { return (0, 0) }
            guard let documentIndex = documents.firstIndex(where: { $0.id == location.documentId }) else { return (0, 0) }
            
            let document = documents[documentIndex]
            for pageIndex in document.pageFrames.indices {
                let pageFrame = document.pageFrames[pageIndex]
                let stringRange = CTFrameGetVisibleStringRange(pageFrame)
                if stringRange.location + stringRange.length > location.offset {
                    return (documentIndex, pageIndex)
                }
            }
            return (documentIndex, 0)
        }
        
        // MARK: - Layout
        
        private func reloadBookLayout(from content: [EPUBDataProviderResult], pageSize: CGSize) {
            let start = Date()
            documents = []
            
            for documentInfo in content {
                var imageIndex = 0
                var imageInfo: [Int: [ImageInfo]] = [:]
                var pageFrames: [CTFrame] = []
                var page = 0
                
                let framesetter = CTFramesetterCreateWithAttributedString(documentInfo.attributedString as CFAttributedString)
                
                var textPosition = 0
                while textPosition < documentInfo.attributedString.length {
                    let path = CGMutablePath()
                    path.addRect(CGRect(origin: .zero, size: pageSize))
                    
                    let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPosition, 0), path, nil)
                    
                    let frameRange = CTFrameGetVisibleStringRange(ctframe)
                    textPosition += max(frameRange.length, 1)
                    
                    pageFrames.append(ctframe)
                    
                    while imageIndex < documentInfo.images.count && documentInfo.images[imageIndex].location < textPosition {
                        let image = documentInfo.images[imageIndex]
                        
                        let lines = CTFrameGetLines(ctframe) as NSArray
                        var origins = [CGPoint](repeating: .zero, count: lines.count)
                        CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), &origins)
                        
                        let location = image.location
       
                        for lineIndex in 0..<lines.count {
                            let line = lines[lineIndex] as! CTLine
                            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun] {
                                for run in glyphRuns {
                                    let runRange = CTRunGetStringRange(run)
                                    if runRange.location > location || runRange.location + runRange.length <= location {
                                        continue
                                    }
                                    
                                    var imgBounds: CGRect = .zero
                                    var ascent: CGFloat = 0
                                    imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
                                    imgBounds.size.height = ascent
                                    
                                    let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                                    imgBounds.origin.x = origins[lineIndex].x + xOffset
                                    imgBounds.origin.y = origins[lineIndex].y
                                    
                                    var images = imageInfo[page] ?? []
                                    images.append(.init(url: image.url, frame: imgBounds))
                                    imageInfo[page] = images
                                    
                                    break
                                }
                            }
                        }
                        
                        imageIndex += 1
                    }
                    
                    page += 1
                }
                
                documents.append(.init(id: documentInfo.documentId, pageFrames: pageFrames, imagesInfo: imageInfo, string: documentInfo.attributedString))
            }
            // TODO: This could be bottleneck, I need to optimize this somehow for huge texts
            /*
             
             Idea - When I open the book, I need to find the place I am in. Is there a faster way then current? If yes, I can find page I need using binary search, display it and then calculate in background all other pages going repeadely in both directions. There should be something like fault system for pages (like I have full array of pagesFrames, but some are loaded and some no.
             */
            print("Time reload book layout = \(Date().timeIntervalSince(start))")
        }
        
        // MARK: - Helper
        
        private func calculateCharactersOffset(for document: Document, page: Int) -> Int {
            let ctFrame = document.pageFrames[page]
            let range = CTFrameGetVisibleStringRange(ctFrame)
            
            return range.location + range.length / 2
        }
    }
}

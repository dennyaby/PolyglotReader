//
//  ReaderViewController.swift
//  MyReader
//
//  Created by  Dennya on 17/09/2023.
//

import UIKit

final class ReaderViewController: UIViewController, Loggable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ReaderCollectionViewCellDelegate {
    
    // MARK: - Nested Types
    
    struct ImageInfo {
        let url: URL
        let frame: CGRect
    }
    
    // MARK: - Properties
    
    private let appManager: AppManager
    private let book: Book
    private let epubDataProvider: EPUBDataProvider
    private var pagesFrames: [[CTFrame]] = []
    private var attributedTexts: [NSAttributedString] = []
    private var imagesInfo: [[Int: [ImageInfo]]] = []
    
    private let collectionView: UICollectionView
    private var horizontalSpacing: CGFloat = 15
    private var pageSize: CGSize = .zero
    
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(nil, for: .normal)
        btn.setTitleColor(.green, for: .normal)
        btn.setImage(UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = ColorStyle.tintColor1
        return btn
    }()
    
    // MARK: - Init
    
    init?(appManager: AppManager, book: Book) {
        guard let epubDataProvider = EPUBDataProvider(appManager: appManager, book: book) else {
            return nil
        }
        self.epubDataProvider = epubDataProvider
        self.appManager = appManager
        self.book = book
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
 
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if view.bounds.size != .zero {
            let pageSize = CGSize(width: floor(collectionView.bounds.width - horizontalSpacing * 2), height: floor(collectionView.bounds.height))
            if pageSize != self.pageSize {
                self.pageSize = pageSize
                
                reloadBookLayout(from: epubDataProvider.bookContents(userTextSettings: .init(fontMultiplier: 1), pageSize: pageSize))
                collectionView.reloadData()
            }
        }
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - View Setup
    
    private func setupView() {
        view.backgroundColor = .white
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        view.addSubview(backButton)
        [backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
         backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15)].activate()
        
        collectionView.register(ReaderCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ReaderCollectionViewCell.self))
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        view.addSubview(collectionView)
        [collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
         collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)].activate()
        
    }
    
    // MARK: - Book Layout
    static var a = 1
    static var b = 1
    private func reloadBookLayout(from content: [EPUBDataProvider.Result]) {
        let start = Date()
        self.pagesFrames = []
        self.attributedTexts = []
        self.imagesInfo = []
        
        for documentInfo in content {
            var imageIndex = 0
            var imageInfo: [Int: [ImageInfo]] = [:]
            var pageFrames: [CTFrame] = []
            var page = 0
            
            let framesetter = CTFramesetterCreateWithAttributedString(documentInfo.attributedString as CFAttributedString)
            
            Self.a += 1
            print("A = \(Self.a)")
            
            if Self.a == 11 {
                print()
            }
            var textPosition = 0
            while textPosition < documentInfo.attributedString.length {
                let path = CGMutablePath()
                path.addRect(CGRect(origin: .zero, size: pageSize))
                
                if Self.a == 12 {
                    print("B = \(Self.b)")
                    Self.b += 1
                }
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
            
            self.imagesInfo.append(imageInfo)
            self.pagesFrames.append(pageFrames)
            
        }
        // TODO: This could be bottleneck, I need to optimize this somehow for huge texts
        /*
         
         Idea - When I open the book, I need to find the place I am in. Is there a faster way then current? If yes, I can find page I need using binary search, display it and then calculate in background all other pages going repeadely in both directions. There should be something like fault system for pages (like I have full array of pagesFrames, but some are loaded and some no.
         */
        print("Time reload book layout = \(Date().timeIntervalSince(start))")
    }
    
    // MARK: - UICollectionViewDataSource && UICollectionViewDelegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return pagesFrames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pagesFrames[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReaderCollectionViewCell.self), for: indexPath) as! ReaderCollectionViewCell
        cell.leadingSpacing = horizontalSpacing
        cell.ctFrame = pagesFrames[indexPath.section][indexPath.item]
        cell.delegate = self
        cell.setNeedsDisplay()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - ReaderCollectionViewCellDelegate
    
    func getImagesToDrawForReaderCollectionViewCell(_ cell: ReaderCollectionViewCell) -> [ReaderCollectionViewCell.ImageInfo] {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return []
        }
        
        guard let imageInfo = self.imagesInfo[indexPath.section][indexPath.item] else {
            return []
        }
        
        var result: [ReaderCollectionViewCell.ImageInfo] = []
        for image in imageInfo {
            guard let uiImage = epubDataProvider.image(for: image.url) else { continue }
            result.append(.init(image: uiImage, frame: image.frame))
        }
        return result
    }
    
    // MARK: - Actions
    
    @objc private func backAction() {
        dismiss(animated: true)
    }
}

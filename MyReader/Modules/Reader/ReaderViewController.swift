//
//  ReaderViewController.swift
//  MyReader
//
//  Created by  Dennya on 17/09/2023.
//

import UIKit

final class ReaderViewController: UIViewController, Loggable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    
    private let appManager: AppManager
    private let book: Book
    private let epubDataProvider: EPUBDataProvider
    private var pagesFrames: [CTFrame] = []
    private var attributedTexts: [NSAttributedString] = []
    
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
                
                reloadBookLayout()
                collectionView.reloadData()
            }
        }
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        attributedTexts = epubDataProvider.bookContents(userTextSettings: .init(fontMultiplier: 1))
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
    
    private func reloadBookLayout() {
        let start = Date()
        self.pagesFrames = []
        
        for attributedText in attributedTexts {
            
            let framesetter = CTFramesetterCreateWithAttributedString(attributedText as CFAttributedString)
            
            var textPosition = 0
            while textPosition < attributedText.length {
                let path = CGMutablePath()
                path.addRect(CGRect(origin: .zero, size: pageSize))
                let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPosition, 0), path, nil)
                
                let frameRange = CTFrameGetVisibleStringRange(ctframe)
                textPosition += frameRange.length
                self.pagesFrames.append(ctframe)
            }
        }
        print("Time reload book layout = \(Date().timeIntervalSince(start))")
    }
    
    // MARK: - UICollectionViewDataSource && UICollectionViewDelegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pagesFrames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReaderCollectionViewCell.self), for: indexPath) as! ReaderCollectionViewCell
        cell.leadingSpacing = horizontalSpacing
        cell.ctFrame = pagesFrames[indexPath.item]
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
    
    // MARK: - Actions
    
    @objc private func backAction() {
        dismiss(animated: true)
    }
}

//
//  ReaderViewController.swift
//  MyReader
//
//  Created by  Dennya on 17/09/2023.
//

import UIKit

// TODO: Perform all content loading in background thread
final class ReaderViewController: UIViewController, Loggable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ReaderCollectionViewCellDelegate {
    
    // MARK: - Nested Types
    
    struct ImageInfo {
        let url: URL
        let frame: CGRect
    }
    
    // MARK: - Properties
    
    private let appManager: AppManager
    private let bookContentManager: BookContentManager
    private let textSelectionManager: TextSelectionManager
    
    private let collectionView: UICollectionView
    private var horizontalSpacing: CGFloat = 15
    private var verticalSpacing: CGFloat = 45
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
        guard let bookContentManager = BookContentManager(appManager: appManager, book: book) else {
            return nil
        }
        self.bookContentManager = bookContentManager
        self.appManager = appManager
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        
        self.textSelectionManager = .init(collectionView: collectionView)
 
        super.init(nibName: nil, bundle: nil)
        
        update(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if view.bounds.size != .zero {
            let pageSize = CGSize(width: floor(collectionView.bounds.width - horizontalSpacing * 2), height: floor(collectionView.bounds.height - verticalSpacing * 2))
            if pageSize != self.pageSize {
                self.pageSize = pageSize
                
                print("Reloading for page size: \(pageSize)")
                bookContentManager.reloadLayout(pageSize: pageSize)
                collectionView.reloadData()
                
                let (section, item) = bookContentManager.getCurrentDocumentAndPageIndexes()
                collectionView.scrollToItem(at: IndexPath(item: item, section: section), at: .centeredHorizontally, animated: false)
                
                let page = bookContentManager.ctFrame(forDocument: section, page: item)
                let string = bookContentManager.string(forDocument: section)
                textSelectionManager.set(ctFrame: page, string: string)
                
                // TODO: Layout is completely broken when turn to landscape mode.
            }
        }
    }
    
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
    
    // MARK: - UICollectionViewDataSource && UICollectionViewDelegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return bookContentManager.numberOfDocuments()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookContentManager.numberOfPages(for: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReaderCollectionViewCell.self), for: indexPath) as! ReaderCollectionViewCell
        cell.leadingSpacing = horizontalSpacing
        cell.topSpacing = verticalSpacing
        cell.ctFrame = bookContentManager.ctFrame(forDocument: indexPath.section, page: indexPath.row)
        cell.delegate = self
        cell.setNeedsDisplay()
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let centerIndexPath = collectionView.getCenterCellIndexPath() else { return }
        
        bookContentManager.saveBookLocation(documentIndex: centerIndexPath.section, page: centerIndexPath.item)
        
        let ctFrame = bookContentManager.ctFrame(forDocument: centerIndexPath.section, page: centerIndexPath.item)
        let string = bookContentManager.string(forDocument: centerIndexPath.section)
        textSelectionManager.set(ctFrame: ctFrame, string: string)
        // TODO: Check that this method is called in every situation when page is changed
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
        return bookContentManager.getImages(for: indexPath.section, page: indexPath.item)
    }
    
    // MARK: - Actions
    
    @objc private func backAction() {
        dismiss(animated: true)
    }
    
    // MARK: - Helper
    
    private func update(horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        textSelectionManager.set(textInsets: .init(top: verticalSpacing, left: horizontalSpacing, bottom: verticalSpacing, right: horizontalSpacing))
    }
}

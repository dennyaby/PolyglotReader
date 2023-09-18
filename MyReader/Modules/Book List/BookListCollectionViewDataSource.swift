//
//  BookListCollectionViewDataSource.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import UIKit

final class BookListCollectionViewDataSourceAndDelegate: NSObject, Loggable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, DataStorageDelegate {//, UICollectionViewDataSource {
    
    static let minBookWidth: CGFloat = 100
    static let spacing: CGFloat = 35
    static let cellId = String(describing: BookListCollectionViewCell.self)
    
    typealias OpenBookHandler = ((Book) -> ())
    
    // MARK: - Properties
    
    private weak var collectionView: UICollectionView?
    private let dataStorage: DataStorage
    private let appFileManager: AppFileManager
    private(set) var books: [Book] = []
    private let coverImagesCache = NSCache<NSURL, UIImage>()
    
    private lazy var booksFolder: URL? = {
        return try? appFileManager.getBooksUrl()
    }()
    
    private var cellSize = CGSize.zero
    private var numberOfColumns: Int
    
    private var openBookAction: OpenBookHandler?
    
    // MARK: - Init
    
    init(dataStorage: DataStorage, appFileManager: AppFileManager, collectionView: UICollectionView) {
        self.dataStorage = dataStorage
        self.appFileManager = appFileManager
        self.collectionView = collectionView
        
        UserSettings.BookList.numberOfColumns.setValue(2)
        
        if let existingValue = UserSettings.BookList.numberOfColumns.getValue(), existingValue >= 1 {
            numberOfColumns = existingValue
        } else {
            numberOfColumns = 1
        }
        super.init()
        
        do {
            self.books = try dataStorage.getAllBooks()
        } catch {
            log("Cannot fetch books on init: \(error)")
        }
       
        dataStorage.delegate = self
        
        collectionView.register(BookListCollectionViewCell.self, forCellWithReuseIdentifier: Self.cellId)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsSelection = true
        
        recalculateCellSize()
    }
    
    // MARK: - Interface
    
    func handleBookOpen(_ block: @escaping OpenBookHandler) {
        self.openBookAction = block
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellId, for: indexPath) as! BookListCollectionViewCell
        
        let book = books[indexPath.item]
        if let bookId = book.bookId, let coverPath = book.coverPath, let booksFolder = booksFolder {
            let coverURL = booksFolder.appendingPathComponent(bookId, isDirectory: true)
                .appendingPathComponent(AppFileManager.contentFolderName, isDirectory: true)
                .appendingPathComponent(coverPath)
            var image: UIImage?
            if let cached = coverImagesCache.object(forKey: coverURL as NSURL) {
                image = cached
            } else {
                if let imageData = try? Data(contentsOf: coverURL), let fetchedImage = UIImage(data: imageData) {
                    image = fetchedImage
                    coverImagesCache.setObject(fetchedImage, forKey: coverURL as NSURL)
                }
            }
            
            if let image = image {
                cell.set(coverImage: image)
                return cell
            }
        }
        
        cell.set(title: book.title, author: book.author)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Self.spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Self.spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Self.spacing, bottom: 0, right: Self.spacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openBookAction?(books[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - Interface
    
    func didLayoutSubviews() {
        recalculateCellSize()
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - DataStorageDelegate
    
    func storage(_ storage: DataStorage, didUpdate books: [Book]) {
        DispatchQueue.main.async {
            self.books = books
            self.collectionView?.reloadData()
        }
    }
    
    // MARK: - Helper
    
    private func recalculateCellSize() {
        guard let width = collectionView?.bounds.width, width > 0 else {
            return
        }
        
        let maxColumnsCount = max(1, Int((width - Self.spacing) / (Self.minBookWidth + Self.spacing)))
        if self.numberOfColumns > maxColumnsCount {
            self.numberOfColumns = maxColumnsCount
            UserSettings.BookList.numberOfColumns.setValue(self.numberOfColumns)
        }
        
        let cellWidth = floor((width - Self.spacing) / CGFloat(self.numberOfColumns)) - Self.spacing
        self.cellSize = BookListCollectionViewCell.cellSizeForCellWith(width: cellWidth)
    }
}

//
//  BookListViewController.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import UIKit

final class BookListViewController: UIViewController, UIDocumentPickerDelegate, Loggable {
    
    enum Error: Swift.Error {
        case bookHasNoBookId
    }
    
    // MARK: - Properties
    
    private let headerView = BookListHeaderView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private let appManager: AppManager
    private let dataStorageInitializeManager = DataStorateInitializationManager()
    private var dataSourceAndDelegate: BookListCollectionViewDataSourceAndDelegate?
    
    // MARK: - Init
    
    init(appManager: AppManager) {
        self.appManager = appManager
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        dataStorageInitializeManager.initialize(dataStorage: appManager.dataStorage, from: self)
        
        dataSourceAndDelegate = BookListCollectionViewDataSourceAndDelegate(dataStorage: appManager.dataStorage, appFileManager: appManager.fileManager, collectionView: collectionView)
        headerView.handleDeleteAction { [weak self] in
            self?.deleteAllBooks()
        }
        
        headerView.handleAddAction { [weak self] in
            self?.importDocument()
        }
        
        dataSourceAndDelegate?.handleBookOpen({ [weak self] book in
            self?.open(book: book)
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dataSourceAndDelegate?.didLayoutSubviews()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(headerView)
        [headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
         headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
         headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)].activate()
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        [collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
         collectionView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
         collectionView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
         collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)].activate()
    }
    
    // MARK: - Logic
    
    private func deleteAllBooks() {
        let allBooks = (try? appManager.dataStorage.getAllBooks()) ?? []
        for book in allBooks {
            delete(book: book)
        }
    }
    
    private func delete(book: Book) {
        if let bookId = book.bookId {
            try? appManager.fileManager.deleteBook(with: bookId)
        }
        
        if let id = book.id {
            try? appManager.dataStorage.delete(bookId: id)
        }
    }
    
    private func open(book: Book) {
        log("Open book with name \(book.title ?? "No name")")
        
        var bookCopy = book
        bookCopy.lastOpenedDate = Date()
        try? appManager.dataStorage.update(book: bookCopy)
        
        guard let readerVC = ReaderViewController(appManager: appManager, book: bookCopy) else {
            let alert = UIAlertController(title: "Error", message: "Cannot open book, try to reimport it to you library.", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        readerVC.modalPresentationStyle = .fullScreen
        present(readerVC, animated: true)
    }
    
    private func importDocument() {
        let controller = UIDocumentPickerViewController(documentTypes: [EPUBParser.epubDocumentIdentifier], in: .import)
        controller.delegate = self
        present(controller, animated: true)
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("Pick documents with urls \(urls)")
        appManager.importBooks(from: urls)
    }
    
    // MARK: - Other
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  CDDataStorage.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import CoreData

final class CDDataStorage: DataStorage {
    
    enum InitializeError: Error {
        case noModelFindInBundle
        case cannotInitializeModel
        case cannotAddPersistentStore
    }
    
    enum StorageError: Error {
        case noManagedObjectContext
        case cannotFindBookWithId
    }
    
    static let sqliteFileName = "db.sqlite"
    
    // MARK: - Properties
    
    weak var delegate: DataStorageDelegate?
    
    private(set) var isInitialized = false
    
    private var storeCoordinator: NSPersistentStoreCoordinator?
    private var viewContext: NSManagedObjectContext?
    private var model: NSManagedObjectModel?
    
    private let fileManager: AppFileManager
    
    private let initializeLock = NSLock()
    
    //    func saveContext () {
    //        let context = persistentContainer.viewContext
    //        if context.hasChanges {
    //            do {
    //                try context.save()
    //            } catch {
    //                // Replace this implementation with code to handle the error appropriately.
    //                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    //                let nserror = error as NSError
    //                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    //            }
    //        }
    //    }
    //}
    
    // MARK: - Init
    
    init(fileManager: AppFileManager) {
        self.fileManager = fileManager
    }
    
    // MARK: - Interface
    
    func initialize() throws {
        initializeLock.lock()
        defer { initializeLock.unlock() }
        guard isInitialized == false else {
            return
        }
        
        let model: NSManagedObjectModel
        if let existingModel = self.model {
            model = existingModel
        } else {
            guard let url = Bundle.main.url(forResource: "MyReader", withExtension: "momd") else {
                throw InitializeError.noModelFindInBundle
            }
            
            guard let newModel = NSManagedObjectModel(contentsOf: url) else {
                throw InitializeError.cannotInitializeModel
            }
            model = newModel
        }
        
        self.model = model
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        self.storeCoordinator = psc
        
        let databaseUrl = try fileManager.urlToCDDatabase()
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseUrl)
        } catch {
            throw InitializeError.cannotAddPersistentStore
        }
        
        viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        viewContext?.persistentStoreCoordinator = psc
        
        self.isInitialized = true
    }
    
    // MARK: - DataStorage
    
    func getAllBooks() throws -> [Book] {
        var result: [Book] = []
        try performSaveMainThread { context in
            let fetchRequest = BookCDModel.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastOpenedDate", ascending: false)]
            let books = try context.fetch(fetchRequest)
            result = books.map(cdBookToBook)
        }
        return result
    }
    
    func importNew(book: Book) throws {
        try performSaveMainThread { context in
            let cdBook = BookCDModel(context: context)
            assignProperties(to: cdBook, from: book)
            try context.save()
            
            notifyDelegateOfUpdate()
        }
    }
    
    func opened(book: Book) throws {
        try performSaveMainThread { context in
            guard let id = book.id, let cdBook = try context.existingObject(with: id) as? BookCDModel else {
                throw StorageError.cannotFindBookWithId
            }
            
            cdBook.lastOpenedDate = Date()
            try context.save()
            notifyDelegateOfUpdate()
        }
    }
    
    func deleted(bookId: Book.ID) throws {
        try performSaveMainThread { context in
            guard let cdBook = try context.existingObject(with: bookId) as? BookCDModel else {
                throw StorageError.cannotFindBookWithId
            }
            context.delete(cdBook)
            try context.save()
            
            notifyDelegateOfUpdate()
        }
    }
    
    // MARK: - Helper
    
    private func performSaveMainThread(_ block: (NSManagedObjectContext) throws -> ()) throws {
        guard isInitialized, let context = viewContext else {
            throw StorageError.noManagedObjectContext
        }
        
        if Thread.isMainThread {
            try block(context)
        } else {
            try DispatchQueue.main.sync {
                try block(context)
            }
        }
    }
    
    private func cdBookToBook(_ cdBook: BookCDModel) -> Book {
        return Book(id: cdBook.objectID, bookId: cdBook.bookId, title: cdBook.title, author: cdBook.author, lastOpenedDate: cdBook.lastOpenedDate, addedDate: cdBook.addedDate, languages: cdBook.languages, coverPath: cdBook.coverPath)
    }
    
    private func assignProperties(to cdBook: BookCDModel, from book: Book) {
        cdBook.title = book.title
        cdBook.author = book.author
        cdBook.addedDate = book.addedDate
        cdBook.bookId = book.bookId
        cdBook.coverPath = book.coverPath
        cdBook.languages = book.languages
        cdBook.lastOpenedDate = book.lastOpenedDate
    }
    
    private func notifyDelegateOfUpdate(books: [Book]? = nil) {
        let allBooks = books ?? (try? getAllBooks()) ?? []
        
        delegate?.storage(self, didUpdate: allBooks)
    }
    
    private func getBook(with id: NSManagedObjectID, contextToUse: NSManagedObjectContext? = nil) -> BookCDModel? {
        guard let context = contextToUse ?? viewContext else {
            return nil
        }
        
        var result: BookCDModel?
        if Thread.isMainThread {
            result = try? context.existingObject(with: id) as? BookCDModel
        } else {
            context.performAndWait { [weak context] in
                result = try? context?.existingObject(with: id) as? BookCDModel
            }
        }
        
        return result
    }
    
}

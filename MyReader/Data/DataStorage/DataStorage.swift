//
//  DataStorage.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import CoreData

protocol DataStorageDelegate: AnyObject {
    func storage(_ storage: DataStorage, didUpdate books: [Book])
}

protocol DataStorage: AnyObject {
    
    var delegate: DataStorageDelegate? { get set }
    
    func initialize() throws
    func getAllBooks() throws -> [Book]
    func update(book: Book) throws
    func delete(bookId: Storage.ID) throws
    func importNew(book: Book) throws
    func highlightsFor(book: Book) throws -> [BookHighlight]
    func add(highlight: BookHighlight, to book: Book) throws
    func delete(highlightId: Storage.ID) throws
    
    // TODO: Implement using CoreData, Realm, SQLIte
}

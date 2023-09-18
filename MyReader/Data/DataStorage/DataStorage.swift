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
    func opened(book: Book) throws
    func deleted(bookId: Book.ID) throws
    func importNew(book: Book) throws
    
    // TODO: Implement using CoreData, Realm, SQLIte
}

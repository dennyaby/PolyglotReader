//
//  Book.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import CoreData

struct Book {
    
    typealias ID = NSManagedObjectID
    
    let id: ID?
    let bookId: String?
    let title: String?
    let author: String?
    let lastOpenedDate: Date?
    let addedDate: Date?
    let languages: String?
    let coverPath: String?
}

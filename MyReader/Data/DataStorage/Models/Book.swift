//
//  Book.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import CoreData

struct Book {
    let id: Storage.ID?
    let bookId: String?
    let title: String?
    let author: String?
    var lastOpenedDate: Date?
    let addedDate: Date?
    let languages: String?
    let coverPath: String?
    var location: BookLocation?
}

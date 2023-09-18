//
//  AppFileManager.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import Foundation

final class AppFileManager {
    
    enum Error: Swift.Error {
        case cannotLocateDirectory(String)
        case cannotCopyFile
    }
    
    static let cdDatabaseFileName = "db.sql"
    static let contentFolderName = "Content"
    /*
     Book storage system:
        Root url  = ../Library/Books
     
        Specific book:
        UUID Random String/
            - Content/[Unzipped epub content]
            - [epub file]
     
     */
    
    // MARK: - Properties
    
    private let fm = FileManager.default
    private var libraryDirUrl: URL?
    private var booksDirUrl: URL?
    private var cacheURL: URL?
    private var documentsDirUrl: URL?
    
    // MARK: - Interface
    
    func urlToCDDatabase() throws -> URL {
        return try getLibraryUrl().appendingPathComponent(Self.cdDatabaseFileName)
    }
    
    func getBookContentDirectory(bookId: String) throws -> URL {
        return try getBooksUrl()
            .appendingPathComponent(bookId, isDirectory: true)
            .appendingPathComponent(Self.contentFolderName, isDirectory: true)
    }
    
    func getBooksUrl() throws -> URL {
        if let existing = booksDirUrl {
            print("There is existing books url")
            return existing
        }
        
        let documentsUrl = try getDocumentsUrl()
        let booksUrl = documentsUrl.appendingPathComponent("Books")
        if !fm.fileExists(atPath: booksUrl.absoluteString) {
            print("No books directory, creating one")
            try fm.createDirectory(at: booksUrl, withIntermediateDirectories: true)
        }
        
        self.booksDirUrl = booksUrl
        return booksUrl
    }
    
    func getLibraryUrl() throws -> URL {
        if let existing = libraryDirUrl {
            return existing
        }
        
        guard let url = fm.urls(for: .libraryDirectory, in: .userDomainMask).last else {
            throw Error.cannotLocateDirectory("Library")
        }
        
        self.libraryDirUrl = url
        return url
    }
    
    func getDocumentsUrl() throws -> URL {
        if let existing = documentsDirUrl {
            return existing
        }
        
        guard let url = fm.urls(for: .documentDirectory, in: .userDomainMask).last else {
            throw Error.cannotLocateDirectory("Documents")
        }
        
        self.documentsDirUrl = url
        return url
    }
    
    func getCacheUrl() throws -> URL {
        if let existing = cacheURL {
            return existing
        }
        
        guard let url = fm.urls(for: .cachesDirectory, in: .userDomainMask).last else {
            throw Error.cannotLocateDirectory("Cache")
        }
        
        self.cacheURL = url
        return url
    }
    
    func copyFile(from source: URL, to destination: URL) throws {
        do {
            try fm.copyItem(at: source, to: destination)
        } catch {
            throw Error.cannotCopyFile
        }
    }
    
    func getRandomUrlForTemporaryDirectory() throws -> URL {
        return try getCacheUrl().appendingPathComponent(RandomStringGenerator.generate(), isDirectory: true)
    }
    
    func getUrlForNewBook(bookId: String = RandomStringGenerator.generate(), createFolders: Bool = true) throws -> URL {
        let booksUrl = try getBooksUrl()
        let newBookUrl = booksUrl.appendingPathComponent(bookId, isDirectory: true)
        
        if createFolders {
            let contentUrl = newBookUrl.appendingPathComponent(Self.contentFolderName, isDirectory: true)
            if fm.fileExists(atPath: newBookUrl.absoluteString) == false {
                try fm.createDirectory(at: contentUrl, withIntermediateDirectories: true)
            }
        }
        return newBookUrl
    }
    
    func deleteBook(with id: String) throws {
        let bookFolderUrl = try getBooksUrl().appendingPathComponent(id, isDirectory: true)
        try fm.removeItem(at: bookFolderUrl)
    }
    
}

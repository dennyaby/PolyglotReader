//
//  BookImportManager.swift
//  MyReader
//
//  Created by  Dennya on 08/09/2023.
//

import UIKit
import Zip

final class BookImportManager: Loggable {
    
    // Import book = unzip, create folder, there create content (folder with what was unziped) and copy epub book file. Then parse, get cover, name, author, language and other metadata and create record in the database.
    
    // Read book = We have a link to content folder, I have to parse it to get information about spine (?), and then use url and parsed info to display content.
    
    // TODO: Should I parse different ways for import and read?
    
    enum Error: Swift.Error {
        case cannotImportBooks
    }
    
    // MARK: - Properties
    
    let fileManager: AppFileManager
    let dataStorage: DataStorage
    let epubImportManager: EPUBParser
    
    // MARK: - Init
    
    init(fileManager: AppFileManager, dataStorage: DataStorage, epubImportManager: EPUBParser) {
        self.fileManager = fileManager
        self.dataStorage = dataStorage
        self.epubImportManager = epubImportManager
    }
    
    // MARK: - Interface
    
    func importBooks(from urls: [URL]) throws {
        for url in urls {
            try importBook(url: url)
        }
    }
    
    func importBook(url: URL) throws {
        let bookId = RandomStringGenerator.generate()
        let newBookUrl: URL
        do {
            newBookUrl = try fileManager.getUrlForNewBook(bookId: bookId)
            print("Get url for the book: \(newBookUrl)")
        } catch {
            print(error)
            throw Error.cannotImportBooks
        }
        
        let fm = FileManager.default
        do {
            let bookFileName = url.lastPathComponent
            
            var epubFileUrl = newBookUrl.appendingPathComponent(bookFileName)
            try fm.copyItem(at: url, to: epubFileUrl)
            log("Copied book to \(epubFileUrl)")
            
            let zipBookFileName = (bookFileName.components(separatedBy: ".").dropLast() + ["zip"]).joined(separator: ".")
            var bookResourceValues = URLResourceValues()
            bookResourceValues.name = zipBookFileName
            try epubFileUrl.setResourceValues(bookResourceValues)
            epubFileUrl = newBookUrl.appendingPathComponent(zipBookFileName)
            log("Renamed book to \(zipBookFileName)")
            log("Epub file url after: \(epubFileUrl)")
            
            let contentFolderUrl = newBookUrl.appendingPathComponent(AppFileManager.contentFolderName, isDirectory: true)
            log("Content folder url: \(contentFolderUrl)")
            
            log("Trying to unzip \(epubFileUrl)\nDestination: \(contentFolderUrl)")
            try Zip.unzipFile(epubFileUrl, destination: contentFolderUrl, overwrite: true, password: nil)
            log("Unziped success")
            
            bookResourceValues.name = bookFileName
            try epubFileUrl.setResourceValues(bookResourceValues)
            log("Renamed book to \(bookFileName)")
            
            let parseResult = try epubImportManager.parse(url: contentFolderUrl)
            log("Received parsing result")
            
            let opfResult = parseResult.opfContainerParserResult
 
            try dataStorage.importNew(book: Book(id: nil, bookId: bookId, title: opfResult.titles.first, author: opfResult.creator, lastOpenedDate: nil, addedDate: Date(), languages: opfResult.languages.joined(separator: ","), coverPath: getPathToCover(parseResult: parseResult), location: nil))
        } catch {
            print(error)
            do {
                try fm.removeItem(at: newBookUrl)
            } catch {
                log("Unable to clean up after failed book import.")
            }
            throw Error.cannotImportBooks
        }
    }
    
    // MARK: - Helper
    
    private func getPathToCover(parseResult result: EPUBParser.Result) -> String? {
        let opfResult = result.opfContainerParserResult
        
        var coverManifestItem: EPUBParser.ManifestItem?
        
        if let manifestItemWithPropertiesSet = opfResult.manifestItems.values.first(where: { manifest in
            if let properties = manifest.properties {
                return properties == .coverImage
            }
            return false
        }) {
            coverManifestItem = manifestItemWithPropertiesSet
        } else {
            if let coverMetaItem = result.opfContainerParserResult.metaItems.first(where: { $0.name == "cover" }), let coverContentValue = coverMetaItem.content {
                coverManifestItem = opfResult.manifestItems.values.first(where: { $0.id == coverContentValue })
            }
        }
        
        guard let coverHref = coverManifestItem?.href else {
            return nil
        }
        
        return result.xmlContainerParserResult.packageBasePath + coverHref
    }
}

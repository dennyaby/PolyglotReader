//
//  AppManager.swift
//  MyReader
//
//  Created by  Dennya on 06/09/2023.
//

import UIKit

protocol AppManager {
    var bookImportManager: BookImportManager { get }
    var fileManager: AppFileManager { get }
    var dataStorage: DataStorage { get }
    var epubImportManager: EPUBParser { get }
    
    func importBooks(from urls: [URL])
}

final class MainAppManager: AppManager {
    
    // MARK: - Properties
    
    let bookImportManager: BookImportManager
    let fileManager: AppFileManager
    let dataStorage: DataStorage
    let epubImportManager: EPUBParser
    
    // MARK: - Init
    
    init() {
        fileManager = AppFileManager()
        epubImportManager = EPUBParser()
        dataStorage = CDDataStorage(fileManager: fileManager)
        bookImportManager = BookImportManager(fileManager: fileManager, dataStorage: dataStorage, epubImportManager: epubImportManager)
    }
    
    // MARK: - Interface
    
    func importBooks(from urls: [URL]) {
        do {
            try bookImportManager.importBooks(from: urls)
        } catch {
            // TODO: Handle import books error
        }
    }
}

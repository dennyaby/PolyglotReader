//
//  DataStorateInitializationManager.swift
//  MyReader
//
//  Created by  Dennya on 16/09/2023.
//

import UIKit

final class DataStorateInitializationManager {
    
    // MARK: - Properties
    
    private weak var viewController: UIViewController?
    private weak var dataStorage: DataStorage?
    
    // MARK: - Interface
    
    func initialize(dataStorage ds: DataStorage, from vc: UIViewController) {
        self.viewController = vc
        self.dataStorage = ds
        
        tryToInitialize()
    }
    
    // MARK: - Helper
    
    private func tryToInitialize() {
        do {
            try dataStorage?.initialize()
        } catch {
            let alert = UIAlertController(title: "Error", message: "Could not initialize data storage, please try again later.", preferredStyle: .alert)
            alert.addAction(.init(title: "Retry", style: .default, handler: { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.tryToInitialize()
                }
            }))
            viewController?.present(alert, animated: true)
        }
    }
}

//
//  ReaderViewController.swift
//  MyReader
//
//  Created by  Dennya on 17/09/2023.
//

import UIKit
import WebKit

final class ReaderViewController: UIViewController, Loggable {
    
    // MARK: - Properties
    
    private let appManager: AppManager
    private let book: Book
    private let epubDataProvider: EPUBDataProvider
    
    
    private let webView = WKWebView()
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(nil, for: .normal)
        btn.setTitleColor(.green, for: .normal)
        btn.setImage(UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = ColorStyle.tintColor1
        return btn
    }()
    
    
    // MARK: - Init
    
    init?(appManager: AppManager, book: Book) {
        guard let epubDataProvider = EPUBDataProvider(appManager: appManager, book: book) else {
            return nil
        }
        self.epubDataProvider = epubDataProvider
        self.appManager = appManager
        self.book = book
 
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        epubDataProvider.loadURLHandler = { [weak self] url in
            self?.webView.load(URLRequest(url: url))
        }
        epubDataProvider.start()
    }
    
    // MARK: - View Setup
    
    private func setupView() {
        view.backgroundColor = .white
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        view.addSubview(backButton)
        [backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
         backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15)].activate()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        [webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         webView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
         webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)].activate()
    }
    
    // MARK: - Actions
    
    @objc private func backAction() {
        dismiss(animated: true)
    }
}

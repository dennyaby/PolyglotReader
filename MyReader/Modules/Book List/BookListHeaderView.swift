//
//  BookListHeaderView.swift
//  MyReader
//
//  Created by  Dennya on 05/09/2023.
//

import UIKit

final class BookListHeaderView: UIView {
    
    // MARK: - Constants
    
    static let height: CGFloat = 50
    static let horizontalSpacing: CGFloat = 16
    
    // MARK: - Properties
    
    private let searchTextField = UITextField()
    private let cancelButton = UIButton()
    private let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(nil, for: .normal)
        btn.setTitleColor(.green, for: .normal)
        btn.setImage(UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = ColorStyle.tintColor1
        return btn
    }()
    
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(nil, for: .normal)
        btn.setTitleColor(.green, for: .normal)
        btn.setImage(UIImage(systemName: "trash")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = ColorStyle.tintColor1
        return btn
    }()
    
    private var addAction: (() -> ())?
    private var deleteAction: (() -> ())?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
//        backgroundColor = .red
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        addSubview(addButton)
        [addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalSpacing),
         addButton.centerYAnchor.constraint(equalTo: centerYAnchor)].activate()
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
        addSubview(deleteButton)
        [deleteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalSpacing),
         deleteButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor)].activate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc private func addButtonAction() {
        addAction?()
    }
    
    @objc private func deleteButtonAction() {
        deleteAction?()
    }
    
    // MARK: - Interface
    
    func handleAddAction(_ block: @escaping () -> ()) {
        self.addAction = block
    }
    
    func handleDeleteAction(_ block: @escaping () -> ()) {
        self.deleteAction = block
    }
    
    // MARK: - UIView Methods
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }
}

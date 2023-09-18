//
//  BookListCollectionViewCell.swift
//  MyReader
//
//  Created by  Dennya on 16/09/2023.
//

import UIKit

final class BookListCollectionViewCell: UICollectionViewCell {
    
    enum CoverStyle {
        case standard
    }
    
    // MARK: - Properties
    
    static let heightToWidth: CGFloat = 1.5
    
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        addSubview(coverImageView)
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        [coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
         coverImageView.topAnchor.constraint(equalTo: topAnchor),
         coverImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
         coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor)].activate()
        
        addSubview(titleLabel)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = FontStyle.smallFont
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        [NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 0.3, constant: 0),
         titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
         titleLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8)].activate()
        
        addSubview(authorLabel)
        authorLabel.textColor = .lightGray
        authorLabel.numberOfLines = 0
        authorLabel.textAlignment = .center
        authorLabel.font = FontStyle.smallFont
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [NSLayoutConstraint(item: authorLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.6, constant: 0),
         authorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
         authorLabel.widthAnchor.constraint(equalTo: titleLabel.widthAnchor)].activate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Interface
    
    func set(coverImage: UIImage) {
        self.coverImageView.image = coverImage
        self.coverImageView.backgroundColor = .clear
        self.titleLabel.isHidden = true
        self.authorLabel.isHidden = true
    }
    
    func set(title: String?, author: String?, coverStyle: CoverStyle = .standard) {
        self.coverImageView.image = nil
        self.coverImageView.backgroundColor = UIColor.darkGray
        self.titleLabel.isHidden = false
        self.titleLabel.text = title
        self.authorLabel.isHidden = false
        self.authorLabel.text = author
    }
    
    static func cellSizeForCellWith(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width * Self.heightToWidth)
    }
}

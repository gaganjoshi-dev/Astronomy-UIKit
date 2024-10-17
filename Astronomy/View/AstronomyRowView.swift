//
//  AstronomyRowView.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import UIKit

/// A simple view designed to show a single Event
class AstronomyRowView: UIView {
    
    var model: Astronomy? {
        didSet {
            titleLabel.text = model?.title
            detailLabel.text = model?.date
            if let image = model?.image {
                imageView.image = image
            } else {
                if model?.mediaType == "image" {
                    imageView.image = UIImage(systemName: "photo")
                } else {
                    imageView.image = UIImage(systemName: "video.square")

                }
                
            }
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 2
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "photo")
        return imageView
    }()
    
    let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .top
        return stackView
    }()
    
    let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        addSubview(horizontalStackView)
        verticalStackView.addArrangedSubview(titleLabel)
        verticalStackView.addArrangedSubview(detailLabel)
        horizontalStackView.addArrangedSubview(imageView)
        horizontalStackView.addArrangedSubview(verticalStackView)
        addAutolayoutSubview(horizontalStackView)
        pinToEdges(horizontalStackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.widthAnchor.constraint(equalToConstant: 80)
        ])
        
    }
    
  
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AstronomyRowView {
    /// A convenience initializer which configures the view with provided event
    convenience init(_ astronomy: Astronomy) {
        self.init(frame: .zero)
        self.model = astronomy
    }
}


class AstronomyRowCell: UITableViewCell {
    
    let astronomyView: AstronomyRowView = {
        let view = AstronomyRowView()
        return view
    }()

    var astronomy: Astronomy? {
        didSet {
            astronomyView.model = astronomy
        }
    }
    
    func setImage(_ image: UIImage?) {
            astronomyView.imageView.image = image
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {
        addAutolayoutSubview(astronomyView)
        NSLayoutConstraint.activate([
            astronomyView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            astronomyView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            astronomyView.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            astronomyView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
        ])
    }
}


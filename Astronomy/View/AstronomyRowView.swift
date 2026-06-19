//
//  AstronomyRowView.swift
//  Astronomy
//

import UIKit

final class AstronomyRowView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 2
        label.textColor = .secondaryLabel
        return label
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "photo")
        return imageView
    }()

    private let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .top
        return stackView
    }()

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with astronomy: Astronomy) {
        titleLabel.text = astronomy.title
        detailLabel.text = astronomy.date

        if let image = astronomy.image {
            imageView.image = image
        } else if astronomy.isImage {
            imageView.image = UIImage(systemName: "photo")
        } else {
            imageView.image = UIImage(systemName: "video.square")
        }
    }

    func resetImage() {
        imageView.image = UIImage(systemName: "photo")
    }

    private func setupViews() {
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
}

final class AstronomyRowCell: UITableViewCell {

    private let astronomyView = AstronomyRowView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        astronomyView.resetImage()
    }

    func configure(with astronomy: Astronomy) {
        astronomyView.configure(with: astronomy)
    }

    func setImage(_ image: UIImage?) {
        astronomyView.imageView.image = image
    }

    private func setupViews() {
        selectionStyle = .none
        addAutolayoutSubview(astronomyView)
        NSLayoutConstraint.activate([
            astronomyView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            astronomyView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            astronomyView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            astronomyView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}

//
//  AstronomyDetailsViewController.swift
//  Astronomy
//

import UIKit
import SafariServices

final class AstronomyDetailsViewController: UIViewController {

    private let viewModel: AstronomyDetailsViewModel

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let imageLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }()

    private let copyrightLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let explanationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var watchVideoButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Watch Video"
        configuration.image = UIImage(systemName: "play.fill")
        configuration.imagePadding = 8
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        return button
    }()

    private var imageHeightConstraint: NSLayoutConstraint?

    init(viewModel: AstronomyDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        setupLayout()
        configureContent()
    }

    private func setupLayout() {
        view.addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(contentStack)

        imageContainer.addAutolayoutSubview(imageView)
        imageContainer.addAutolayoutSubview(imageLoadingIndicator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            imageLoadingIndicator.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
        ])

        imageHeightConstraint = imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: 0.66)
        imageHeightConstraint?.isActive = true
    }

    private func configureContent() {
        dateLabel.text = formattedDate(viewModel.date)
        explanationLabel.text = viewModel.descriptionText

        if let copyright = viewModel.copyright, !copyright.isEmpty {
            copyrightLabel.text = "© \(copyright)"
            copyrightLabel.isHidden = false
        } else {
            copyrightLabel.isHidden = true
        }

        contentStack.addArrangedSubview(imageContainer)
        contentStack.addArrangedSubview(dateLabel)
        if !copyrightLabel.isHidden {
            contentStack.addArrangedSubview(copyrightLabel)
        }

        if viewModel.isImage {
            imageView.image = viewModel.lowResImage
            if viewModel.hasHDURL {
                imageLoadingIndicator.startAnimating()
                viewModel.delegate = self
                viewModel.downloadHDImage()
            }
        } else {
            let configuration = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
            imageView.image = UIImage(systemName: "video", withConfiguration: configuration)
            imageView.tintColor = .tertiaryLabel
            imageView.contentMode = .center
            contentStack.addArrangedSubview(watchVideoButton)
        }

        contentStack.addArrangedSubview(explanationLabel)
    }

    private func formattedDate(_ isoDate: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: isoDate) else { return isoDate }

        let display = DateFormatter()
        display.dateStyle = .long
        display.timeStyle = .none
        return display.string(from: date)
    }

    @objc private func playVideo() {
        guard let url = URL(string: viewModel.url) else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}

extension AstronomyDetailsViewController: AstronomyDetailsViewModelDelegate {
    func didUpdateHDImage(_ image: UIImage) {
        imageLoadingIndicator.stopAnimating()
        imageView.contentMode = .scaleAspectFit
        imageView.image = image

        let aspectRatio = image.size.height / max(image.size.width, 1)
        imageHeightConstraint?.isActive = false
        imageHeightConstraint = imageContainer.heightAnchor.constraint(
            equalTo: imageContainer.widthAnchor,
            multiplier: min(max(aspectRatio, 0.45), 1.35)
        )
        imageHeightConstraint?.isActive = true
    }
}

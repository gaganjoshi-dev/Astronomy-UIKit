//
//  AstronomyDetailsViewController.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-14.
//
import UIKit
import SafariServices

class AstronomyDetailsViewController: UIViewController {
    
    private let viewModel: AstronomyDetailsViewModel
    
    init(viewModel: AstronomyDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .justified
        label.font  = .preferredFont(forTextStyle: .headline)
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .top
        stackView.backgroundColor = .white
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        
        setupView()
    }
    
    private func setupView() {
        
        
        self.view.backgroundColor = .systemBackground
        view.addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stackView)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(descriptionLabel)
        
        //        scrollView.addAutolayoutSubview(stackView)
        //        view.addAutolayoutSubview(scrollView)
        
        view.pinToEdges(scrollView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 300),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor) //
        ])
        
        
        title = "Astronomy Details"
        
        if viewModel.mediaType == "image" {
            imageView.image = viewModel.lowResImage
            viewModel.delegate = self
            viewModel.downloadHDImage()
        } else {
            let configuration = UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)
            let image = UIImage(systemName: "video.square", withConfiguration: configuration)
            imageView.image = image
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playVideo))
        }
       
        descriptionLabel.text = viewModel.descriptionText
        
       
    }
    
    @objc
    func playVideo()  {

        openYouTubeVideoInSafariViewController(videoURL: viewModel.url ?? "", from: self)
      
    }
    
    func openYouTubeVideoInSafariViewController(videoURL: String, from viewController: UIViewController) {
        if let url = URL(string: videoURL) {
            let safariVC = SFSafariViewController(url: url)
            viewController.present(safariVC, animated: true, completion: nil)
        }
    }
}

extension AstronomyDetailsViewController: AstronomyDetailsViewModelDelegate {
    func didUpdateHDImage(_ image: UIImage) {
        imageView.image = image
        print("HD Image Updated")
    }
    
    
}

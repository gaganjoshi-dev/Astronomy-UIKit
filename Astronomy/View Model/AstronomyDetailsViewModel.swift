//
//  AstronomyDetailsViewModel.swift
//  Astronomy
//

import Foundation
import UIKit

protocol AstronomyDetailsViewModelDelegate: AnyObject {
    func didUpdateHDImage(_ image: UIImage)
}

@MainActor
final class AstronomyDetailsViewModel {
    private let astronomy: Astronomy
    private let imageLoader: ImageLoader

    weak var delegate: AstronomyDetailsViewModelDelegate?

    var descriptionText: String { astronomy.explanation }
    var lowResImage: UIImage? { astronomy.image }
    var mediaType: String { astronomy.mediaType }
    var url: String { astronomy.url }
    var isImage: Bool { astronomy.isImage }

    init(astronomy: Astronomy, imageLoader: ImageLoader = .shared) {
        self.astronomy = astronomy
        self.imageLoader = imageLoader
    }

    func downloadHDImage() {
        guard let hdURL = astronomy.hdurl else { return }

        Task {
            guard let image = await imageLoader.image(for: hdURL) else { return }
            delegate?.didUpdateHDImage(image)
        }
    }
}

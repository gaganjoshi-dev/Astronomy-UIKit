//
//  AstronomyDetailsViewModel.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-14.
//
import Foundation
import UIKit

protocol AstronomyDetailsViewModelDelegate: AnyObject {
    func didUpdateHDImage(_ image: UIImage)
}

class AstronomyDetailsViewModel {
    private var astronomy: Astronomy
    private let mediaDownloader: MediaDownloader

    weak var delegate: AstronomyDetailsViewModelDelegate?

    var descriptionText: String {
        return astronomy.explanation
    }

    var lowResImage: UIImage? {
        return astronomy.image
    }
    
    var mediaType: String {
        return astronomy.mediaType
    }
    
    var url: String? {
        return astronomy.url
    }

    init(astronomy: Astronomy,_ mediaDownloader: MediaDownloader = MediaDownloader()) {
        self.astronomy = astronomy
        self.mediaDownloader = mediaDownloader
    }

    // Function to download the image asynchronously
    func downloadHDImage() {
        
        guard let hdUrl = astronomy.hdurl else {
            return
        }
        
        Task { [weak self] in
            
            guard let self = self else { return }

            if let image = await self.mediaDownloader.downloadImage(from: hdUrl) {
                DispatchQueue.main.async {
                    self.delegate?.didUpdateHDImage(image)
                }
            }
        }
    }
    
}

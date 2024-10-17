//
//  AstronomyListViewModel.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import Foundation
import UIKit

protocol AstronomyListViewModelDelegate: AnyObject {
    func didUpdateAstronomies()
    func didUpdateImage(for indexpath: IndexPath,image: UIImage)
    
}

@MainActor
class AstronomyListViewModel: ObservableObject {
    weak var delegate: AstronomyListViewModelDelegate?
    
    
    var astronomies: [Astronomy] = []
    
    
    private let astronomyService: AstronomyService
    private let mediaDownloader: MediaDownloader
    
    
    init(_ astronomyService: AstronomyService = AstronomyService(),_ mediaDownloader: MediaDownloader = MediaDownloader()) {
        self.astronomyService = astronomyService
        self.mediaDownloader = mediaDownloader
    }
    
    func loadAstronomy() async {
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: currentDate) else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Format the start and end dates as strings
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: currentDate)
        
        do {
            let fetchedAstronomies = try await astronomyService.getAstronomies(from: startDateString, to: endDateString)
            DispatchQueue.main.async {
                self.astronomies = fetchedAstronomies
                self.delegate?.didUpdateAstronomies()
            }
        }
        catch {
            print("Error fetching astronomy data: \(error.localizedDescription)")
        }
        
    }
    
    
    // Function to download the image asynchronously
    func downloadImage(for indexPath: IndexPath, astronomy: Astronomy) {
        Task { [weak self] in
            if let image = await self?.mediaDownloader.downloadImage(from: astronomy.url) {
                self?.astronomies[indexPath.row].image = image
                
                DispatchQueue.main.async {
                    print("update image at \(indexPath.row)")
                    self?.delegate?.didUpdateImage(for: indexPath, image: image)
                }
            }
        }
    }
    
    
   
    
}

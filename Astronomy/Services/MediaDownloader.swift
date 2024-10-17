//
//  MediaDownloader.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import AVFoundation
import UIKit

class MediaDownloader {
    // Function to download image asynchronously
    func downloadImage(from urlString: String) async -> UIImage? {
       
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
    
   
    
}

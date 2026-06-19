//
//  ImageLoader.swift
//  Astronomy
//

import UIKit

/// Coordinates image downloads with in-memory caching and in-flight deduplication.
actor ImageLoader {
    static let shared = ImageLoader()

    private let session: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    init(session: URLSession = .shared) {
        self.session = session
        memoryCache.countLimit = 200
    }

    func image(for urlString: String) async -> UIImage? {
        let cacheKey = urlString as NSString

        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }

        if let existingTask = inFlight[urlString] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    return nil
                }
                return UIImage(data: data)
            } catch {
                return nil
            }
        }

        inFlight[urlString] = task
        let image = await task.value
        inFlight[urlString] = nil

        if let image {
            memoryCache.setObject(image, forKey: cacheKey)
        }
        return image
    }

    func cancelLoad(for urlString: String) {
        inFlight[urlString]?.cancel()
        inFlight[urlString] = nil
    }
}

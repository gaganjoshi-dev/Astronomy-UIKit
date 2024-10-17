//
//  AstronomyService.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import Foundation

enum NetworkError: Error {
    case decodingError
    case domainError
    case urlError
    case serverError(statusCode : Int)
}

class AstronomyService {
    
    private let baseURL = "https://api.nasa.gov/planetary/apod"
    private let apiKey = "DEMO_KEY" // Replace with your API key
    
    func getAstronomies(from startDate: String,to endDate: String) async throws -> [Astronomy] {
        
        guard var components = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        // Add query items for start date, end date, and API key
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
            throw NetworkError.serverError(statusCode: statusCode)
        }
        let articleList = try? JSONDecoder().decode([Astronomy].self, from: data)
        guard let articleList = articleList else  { throw NetworkError.decodingError }
        return articleList
        
    }
    
}

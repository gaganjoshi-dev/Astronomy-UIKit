//
//  AstronomyService.swift
//  Astronomy
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case decodingError(underlying: Error)
    case serverError(statusCode: Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .decodingError(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .serverError(let statusCode):
            switch statusCode {
            case 429:
                return """
                NASA API rate limit reached (too many requests). \
                Add your own key in Config/Secrets.xcconfig — get one free at api.nasa.gov — \
                or wait about an hour and retry.
                """
            default:
                return "Server returned status code \(statusCode)"
            }
        case .emptyResponse:
            return "No astronomy data was returned"
        }
    }
}

protocol AstronomyNetworkServiceProtocol {
    func getAstronomies(from startDate: String, to endDate: String) async throws -> [Astronomy]
}

final class AstronomyService: AstronomyNetworkServiceProtocol {
    private let baseURL = "https://api.nasa.gov/planetary/apod"
    private let apiKey = APIConfiguration.nasaAPIKey
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func getAstronomies(from startDate: String, to endDate: String) async throws -> [Astronomy] {
        guard var components = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        DiagnosticsLogger.logAPIRequest(url: url, method: "GET")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            DiagnosticsLogger.logAPIError(url: url, statusCode: nil, headers: [:], error: error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let statusCode = http?.statusCode ?? -1
        let headers = http?.allHeaderFields ?? [:]

        if !(200...299).contains(statusCode) {
            DiagnosticsLogger.logAPIError(
                url: url,
                statusCode: statusCode,
                headers: headers,
                error: NetworkError.serverError(statusCode: statusCode)
            )
            throw NetworkError.serverError(statusCode: statusCode)
        }

        do {
            let decoded: [Astronomy]
            if let list = try? JSONDecoder().decode([Astronomy].self, from: data) {
                decoded = list
            } else {
                decoded = [try JSONDecoder().decode(Astronomy.self, from: data)]
            }
            let sorted = decoded.sorted { $0.date > $1.date }
            DiagnosticsLogger.logAPIResponse(
                url: url,
                statusCode: statusCode,
                headers: headers,
                data: data,
                itemCount: sorted.count
            )
            return sorted
        } catch {
            DiagnosticsLogger.logAPIError(url: url, statusCode: statusCode, headers: headers, error: error)
            throw NetworkError.decodingError(underlying: error)
        }
    }
}

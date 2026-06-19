//
//  Astronomy.swift
//  Astronomy
//
import UIKit

enum MediaType: String, Codable {
    case image
    case video
}

struct Astronomy: Codable, Identifiable {
    let copyright: String?
    let date: String
    let explanation: String
    let hdurl: String?
    let mediaType: String
    let serviceVersion: String
    let title: String
    let url: String

    /// Transient UI state — not persisted or encoded.
    var image: UIImage? = nil
    var id: String { date }
    var isImage: Bool { mediaType == MediaType.image.rawValue }

    enum CodingKeys: String, CodingKey {
        case copyright
        case date
        case explanation
        case hdurl
        case mediaType = "media_type"
        case serviceVersion = "service_version"
        case title
        case url
    }
}

enum AstronomyConstants {
    static let historyDays = 100
    static let pageSize = 15
    static let prefetchThreshold = 5
    static let apiChunkSize = 30
}

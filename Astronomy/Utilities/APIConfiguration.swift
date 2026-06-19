//
//  APIConfiguration.swift
//  Astronomy
//

import Foundation

enum APIConfiguration {

    private static let placeholderKey = "your_api_key_here"

    /// NASA APOD API key — from Info.plist, populated via `Config/Base.xcconfig` at build time.
    static var nasaAPIKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "NASA_API_KEY") as? String,
            !key.isEmpty,
            key != placeholderKey,
            key != "$(NASA_API_KEY)"
        else {
            return "DEMO_KEY"
        }
        return key
    }

    static var isUsingDemoKey: Bool {
        nasaAPIKey == "DEMO_KEY"
    }
}

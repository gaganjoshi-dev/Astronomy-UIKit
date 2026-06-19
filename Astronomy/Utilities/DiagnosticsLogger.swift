//
//  DiagnosticsLogger.swift
//  Astronomy
//

import Foundation
import os

/// Multi-line diagnostic logging with visible separators for Xcode console.
enum DiagnosticsLogger {

    private static let separator = String(repeating: "═", count: 72)

    static func block(_ logger: Logger, title: String, lines: [String]) {
        #if DEBUG
        let body = ([separator, "▶ \(title)", separator] + lines + [separator]).joined(separator: "\n")
        logger.info("\(body)")
        #endif
    }

    // MARK: - Network

    static func logAPIRequest(url: URL, method: String = "GET") {
        let sanitized = sanitizeURL(url)
        var lines = [
            "SOURCE: NASA APOD API",
            "METHOD: \(method)",
            "URL: \(sanitized)"
        ]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems, !queryItems.isEmpty
        {
            lines.append("QUERY:")
            for item in queryItems {
                let value = item.name == "api_key" ? maskAPIKey(item.value) : (item.value ?? "")
                lines.append("  • \(item.name) = \(value)")
            }
        }
        lines.append("HEADERS: (default URLSession — no custom headers)")
        block(AppLogger.network, title: "API REQUEST", lines: lines)
    }

    static func logAPIResponse(
        url: URL,
        statusCode: Int,
        headers: [AnyHashable: Any],
        data: Data,
        itemCount: Int?
    ) {
        let sanitized = sanitizeURL(url)
        var lines = [
            "SOURCE: NASA APOD API",
            "URL: \(sanitized)",
            "STATUS: \(statusCode)",
            "BODY SIZE: \(data.count) bytes"
        ]
        if !headers.isEmpty {
            lines.append("RESPONSE HEADERS:")
            for (key, value) in headers.sorted(by: { "\($0.key)" < "\($1.key)" }) {
                lines.append("  • \(key): \(value)")
            }
        }
        if let preview = responseBodyPreview(data) {
            lines.append("BODY PREVIEW:")
            lines.append(preview)
        }
        if let itemCount {
            lines.append("DECODED ITEMS: \(itemCount)")
        }
        block(AppLogger.network, title: "API RESPONSE ✓", lines: lines)
    }

    static func logAPIError(url: URL, statusCode: Int?, headers: [AnyHashable: Any], error: Error) {
        let sanitized = sanitizeURL(url)
        var lines = [
            "SOURCE: NASA APOD API",
            "URL: \(sanitized)",
            "ERROR: \(error.localizedDescription)"
        ]
        if let statusCode {
            lines.append("STATUS: \(statusCode)")
        }
        if !headers.isEmpty {
            lines.append("RESPONSE HEADERS:")
            for (key, value) in headers.sorted(by: { "\($0.key)" < "\($1.key)" }) {
                lines.append("  • \(key): \(value)")
            }
        }
        block(AppLogger.network, title: "API RESPONSE ✗", lines: lines)
    }

    // MARK: - Core Data

    static func logCoreDataSave(count: Int, dates: [String]) {
        block(AppLogger.persistence, title: "CORE DATA SAVE", lines: [
            "OPERATION: upsert",
            "RECORDS: \(count)",
            "DATES: \(dates.joined(separator: ", "))"
        ])
    }

    static func logCoreDataFetch(before: String?, limit: Int, items: [Astronomy]) {
        let titles = items.map { "\($0.date) — \($0.title)" }
        block(AppLogger.persistence, title: "CORE DATA FETCH", lines: [
            "OPERATION: read page",
            "PREDICATE: date < \(before ?? "(none — newest first)")",
            "LIMIT: \(limit)",
            "RESULT COUNT: \(items.count)",
            "ITEMS:",
        ] + titles.map { "  • \($0)" })
    }

    // MARK: - Repository

    static func logRepositoryNetworkPage(count: Int, dateRange: String, daysOffset: Int) {
        block(AppLogger.repository, title: "REPOSITORY → NETWORK", lines: [
            "DATA SOURCE: NASA API (network-first)",
            "DATE RANGE: \(dateRange)",
            "DAYS OFFSET: \(daysOffset)",
            "ITEMS RETURNED: \(count)"
        ])
    }

    static func logRepositoryCacheFallback(count: Int, error: String, before: String?) {
        block(AppLogger.repository, title: "REPOSITORY → CORE DATA", lines: [
            "DATA SOURCE: Core Data (network failed)",
            "NETWORK ERROR: \(error)",
            "FETCH BEFORE: \(before ?? "(none)")",
            "ITEMS RETURNED: \(count)"
        ])
    }

    // MARK: - Helpers

    private static func sanitizeURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.queryItems = components.queryItems?.map { item in
            guard item.name == "api_key" else { return item }
            return URLQueryItem(name: item.name, value: maskAPIKey(item.value))
        }
        return components.string ?? url.absoluteString
    }

    private static func maskAPIKey(_ value: String?) -> String {
        guard let value, value.count > 8 else { return "***" }
        let prefix = value.prefix(4)
        let suffix = value.suffix(4)
        return "\(prefix)…\(suffix) (masked)"
    }

    private static func responseBodyPreview(_ data: Data, maxLength: Int = 800) -> String? {
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return nil }
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "\n… (\(text.count - maxLength) more characters)"
    }
}

//
//  AstronomyDateHelper.swift
//  Astronomy
//

import Foundation

enum AstronomyDateHelper {
    private static let calendar = Calendar.current
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Returns an inclusive NASA API date range for the next feed page (newest → oldest).
    static func pageRange(
        daysAlreadyLoaded: Int,
        pageSize: Int,
        maxHistoryDays: Int
    ) -> (start: String, end: String)? {
        guard daysAlreadyLoaded < maxHistoryDays else { return nil }

        let today = Date()
        let daysInPage = min(pageSize, maxHistoryDays - daysAlreadyLoaded)

        guard
            let endDate = calendar.date(byAdding: .day, value: -daysAlreadyLoaded, to: today),
            let startDate = calendar.date(
                byAdding: .day,
                value: -(daysAlreadyLoaded + daysInPage - 1),
                to: today
            )
        else {
            return nil
        }

        return (dateFormatter.string(from: startDate), dateFormatter.string(from: endDate))
    }

    static func hasMorePages(daysLoaded: Int, maxHistoryDays: Int) -> Bool {
        daysLoaded < maxHistoryDays
    }

    static func daysConsumed(inPage pageSize: Int, daysAlreadyLoaded: Int, maxHistoryDays: Int) -> Int {
        min(pageSize, maxHistoryDays - daysAlreadyLoaded)
    }
}

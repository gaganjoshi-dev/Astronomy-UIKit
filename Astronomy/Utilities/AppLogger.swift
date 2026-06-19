//
//  AppLogger.swift
//  Astronomy
//

import Foundation
import os

/// Centralized logging. Visible in Xcode's debug console and Console.app.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gagan.Astronomy"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let repository = Logger(subsystem: subsystem, category: "Repository")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let feed = Logger(subsystem: subsystem, category: "Feed")
    static let images = Logger(subsystem: subsystem, category: "Images")
}

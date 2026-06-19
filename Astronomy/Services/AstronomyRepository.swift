//
//  AstronomyRepository.swift
//  Astronomy
//

import Foundation

enum AstronomyDataSource: Equatable {
    case network
    case offlineCache
}

struct AstronomyPageResult: Equatable {
    let items: [Astronomy]
    let source: AstronomyDataSource
    let hasMore: Bool
    let fallbackError: String?

    static func == (lhs: AstronomyPageResult, rhs: AstronomyPageResult) -> Bool {
        lhs.items.map(\.date) == rhs.items.map(\.date)
            && lhs.source == rhs.source
            && lhs.hasMore == rhs.hasMore
            && lhs.fallbackError == rhs.fallbackError
    }
}

protocol AstronomyRepositoryProtocol: Sendable {
    func loadPage(daysAlreadyLoaded: Int, oldestLoadedDate: String?) async -> AstronomyPageResult
}

/// Network-first repository with paginated loading and Core Data offline fallback.
actor AstronomyRepository: AstronomyRepositoryProtocol {
    private let networkService: AstronomyNetworkServiceProtocol
    private let persistenceStore: AstronomyPersistenceStore
    private let historyDays: Int
    private let pageSize: Int

    init(
        networkService: AstronomyNetworkServiceProtocol,
        persistenceStore: AstronomyPersistenceStore,
        historyDays: Int = AstronomyConstants.historyDays,
        pageSize: Int = AstronomyConstants.pageSize
    ) {
        self.networkService = networkService
        self.persistenceStore = persistenceStore
        self.historyDays = historyDays
        self.pageSize = pageSize
    }

    /// Loads the next page of the feed. Pass cumulative `daysAlreadyLoaded` from prior pages.
    func loadPage(daysAlreadyLoaded: Int, oldestLoadedDate: String?) async -> AstronomyPageResult {
        let daysConsumed = AstronomyDateHelper.daysConsumed(
            inPage: pageSize,
            daysAlreadyLoaded: daysAlreadyLoaded,
            maxHistoryDays: historyDays
        )
        let nextDaysLoaded = daysAlreadyLoaded + daysConsumed
        let hasMore = AstronomyDateHelper.hasMorePages(daysLoaded: nextDaysLoaded, maxHistoryDays: historyDays)

        guard daysConsumed > 0 else {
            return AstronomyPageResult(items: [], source: .network, hasMore: false, fallbackError: nil)
        }

        if let range = AstronomyDateHelper.pageRange(
            daysAlreadyLoaded: daysAlreadyLoaded,
            pageSize: pageSize,
            maxHistoryDays: historyDays
        ) {
            do {
                let fetched = try await networkService.getAstronomies(from: range.start, to: range.end)
                try await persistenceStore.save(fetched)
                DiagnosticsLogger.logRepositoryNetworkPage(
                    count: fetched.count,
                    dateRange: "\(range.start) → \(range.end)",
                    daysOffset: daysAlreadyLoaded
                )
                return AstronomyPageResult(
                    items: fetched,
                    source: .network,
                    hasMore: hasMore,
                    fallbackError: nil
                )
            } catch {
                let cached = await persistenceStore.fetchAstronomies(before: oldestLoadedDate, limit: pageSize)
                DiagnosticsLogger.logRepositoryCacheFallback(
                    count: cached.count,
                    error: error.localizedDescription,
                    before: oldestLoadedDate
                )
                return AstronomyPageResult(
                    items: cached,
                    source: .offlineCache,
                    hasMore: hasMore && !cached.isEmpty,
                    fallbackError: cached.isEmpty ? error.localizedDescription : error.localizedDescription
                )
            }
        }

        return AstronomyPageResult(items: [], source: .network, hasMore: false, fallbackError: nil)
    }
}

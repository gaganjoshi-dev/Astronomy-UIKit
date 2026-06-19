//
//  AstronomyListViewModel.swift
//  Astronomy
//

import Foundation
import UIKit

protocol AstronomyListViewModelDelegate: AnyObject {
    func didUpdateFeed(animatingDifferences: Bool)
    func didUpdateImage(for date: String, image: UIImage)
    func didUpdateLoadingState()
    func didUpdateLoadingMore(_ isLoading: Bool)
    func didUpdateDataSourceBanner(message: String?)
    func didUpdateEndOfFeed(_ isAtEnd: Bool)
}

enum AstronomyListLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

@MainActor
final class AstronomyListViewModel {
    weak var delegate: AstronomyListViewModelDelegate?

    private(set) var astronomies: [Astronomy] = []
    private(set) var loadingState: AstronomyListLoadingState = .idle
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = true
    private(set) var dataSource: AstronomyDataSource?

    private let repository: any AstronomyRepositoryProtocol
    private let imageLoader: ImageLoader

    private var daysLoaded = 0
    private var feedGeneration = 0

    init(repository: any AstronomyRepositoryProtocol, imageLoader: ImageLoader = .shared) {
        self.repository = repository
        self.imageLoader = imageLoader
    }

    func refresh() async {
        feedGeneration += 1
        AppLogger.feed.info("Feed refresh started (generation \(self.feedGeneration))")
        daysLoaded = 0
        hasMorePages = true
        isLoadingMore = false
        astronomies = []
        dataSource = nil
        await loadNextPage(isInitial: true)
    }

    func loadNextPageIfNeeded(currentRow: Int) {
        guard hasMorePages, !isLoadingMore, loadingState != .loading else { return }
        guard !astronomies.isEmpty else { return }
        guard currentRow >= astronomies.count - AstronomyConstants.prefetchThreshold else { return }

        isLoadingMore = true
        delegate?.didUpdateLoadingMore(true)

        let generation = feedGeneration
        Task { [weak self] in
            await self?.loadNextPage(isInitial: false, generation: generation)
        }
    }

    func loadImage(for astronomy: Astronomy) {
        guard astronomy.isImage, astronomy.image == nil else { return }

        let date = astronomy.date
        Task { [weak self] in
            guard let self else { return }
            let image = await imageLoader.image(for: astronomy.url)
            guard let image,
                  let index = astronomies.firstIndex(where: { $0.date == date }) else { return }

            astronomies[index].image = image
            delegate?.didUpdateImage(for: date, image: image)
        }
    }

    func astronomy(at index: Int) -> Astronomy? {
        guard astronomies.indices.contains(index) else { return nil }
        return astronomies[index]
    }

    func astronomy(withDate date: String) -> Astronomy? {
        astronomies.first { $0.date == date }
    }

    private func loadNextPage(isInitial: Bool, generation: Int? = nil) async {
        if isInitial {
            loadingState = .loading
            delegate?.didUpdateLoadingState()
        }

        let activeGeneration = generation ?? feedGeneration
        let oldestDate = astronomies.last?.date
        let result = await repository.loadPage(daysAlreadyLoaded: daysLoaded, oldestLoadedDate: oldestDate)

        guard isInitial || activeGeneration == feedGeneration else {
            finishLoadingMoreIfNeeded(isInitial: isInitial)
            return
        }

        let daysConsumed = AstronomyDateHelper.daysConsumed(
            inPage: AstronomyConstants.pageSize,
            daysAlreadyLoaded: daysLoaded,
            maxHistoryDays: AstronomyConstants.historyDays
        )
        daysLoaded += daysConsumed
        hasMorePages = result.hasMore

        if isInitial {
            astronomies = result.items
            dataSource = result.source

            if result.items.isEmpty, let error = result.fallbackError {
                loadingState = .failed(error)
                hasMorePages = false
                delegate?.didUpdateDataSourceBanner(message: nil)
                delegate?.didUpdateEndOfFeed(false)
            } else {
                loadingState = .loaded
                updateBanner(for: result)
                delegate?.didUpdateEndOfFeed(!hasMorePages)
            }

            delegate?.didUpdateLoadingState()
            delegate?.didUpdateFeed(animatingDifferences: false)
            return
        }

        defer { finishLoadingMoreIfNeeded(isInitial: false) }

        guard activeGeneration == feedGeneration else { return }

        if result.items.isEmpty {
            hasMorePages = false
            delegate?.didUpdateEndOfFeed(true)
            return
        }

        let existingDates = Set(astronomies.map(\.date))
        let newItems = result.items.filter { !existingDates.contains($0.date) }

        if newItems.isEmpty {
            // Window advanced but every item was already shown — keep paging if history remains.
            if hasMorePages, activeGeneration == feedGeneration {
                await loadNextPage(isInitial: false, generation: activeGeneration)
            } else {
                delegate?.didUpdateEndOfFeed(true)
            }
            return
        }

        astronomies.append(contentsOf: newItems)
        dataSource = result.source

        AppLogger.feed.info("Appended \(newItems.count) item(s), total=\(self.astronomies.count), hasMore=\(self.hasMorePages)")

        delegate?.didUpdateFeed(animatingDifferences: true)

        if result.source == .offlineCache {
            updateBanner(for: result)
        }

        delegate?.didUpdateEndOfFeed(!hasMorePages)
    }

    private func finishLoadingMoreIfNeeded(isInitial: Bool) {
        guard !isInitial else { return }
        isLoadingMore = false
        delegate?.didUpdateLoadingMore(false)
    }

    private func updateBanner(for result: AstronomyPageResult) {
        switch result.source {
        case .network:
            delegate?.didUpdateDataSourceBanner(message: nil)
        case .offlineCache:
            let message = result.fallbackError.map {
                "Offline — showing saved data. (\($0))"
            } ?? "Offline — showing saved data."
            delegate?.didUpdateDataSourceBanner(message: message)
        }
    }
}

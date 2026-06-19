//
//  AstronomyListViewModelTests.swift
//  AstronomyTests
//

import XCTest
import UIKit
@testable import Astronomy

@MainActor
final class AstronomyListViewModelTests: XCTestCase {

    func testRefreshLoadsFirstPage() async {
        let mock = MockAstronomyRepository()
        mock.enqueue(
            AstronomyPageResult(
                items: [makeAstronomy(date: "2024-06-19", title: "Today")],
                source: .network,
                hasMore: true,
                fallbackError: nil
            )
        )

        let viewModel = AstronomyListViewModel(repository: mock)
        let delegate = MockFeedDelegate()
        viewModel.delegate = delegate

        await viewModel.refresh()

        XCTAssertEqual(viewModel.astronomies.count, 1)
        XCTAssertEqual(viewModel.astronomies.first?.title, "Today")
        XCTAssertEqual(viewModel.loadingState, .loaded)
        XCTAssertEqual(viewModel.dataSource, .network)
        XCTAssertTrue(viewModel.hasMorePages)
        XCTAssertEqual(delegate.feedUpdateCount, 1)
        XCTAssertEqual(delegate.lastAnimatingDifferences, false)
    }

    func testLoadNextPageIfNeededDoesNotFireFarFromEnd() async {
        let mock = MockAstronomyRepository()
        mock.enqueue(
            AstronomyPageResult(
                items: (0..<20).map { makeAstronomy(date: "2024-06-\(String(format: "%02d", $0 + 1))", title: "Item \($0)") },
                source: .network,
                hasMore: true,
                fallbackError: nil
            )
        )

        let viewModel = AstronomyListViewModel(repository: mock)
        await viewModel.refresh()

        viewModel.loadNextPageIfNeeded(currentRow: 0)

        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertEqual(mock.loadPageCallCount, 1)
    }

    func testLoadNextPageIfNeededFiresNearEnd() async {
        let mock = MockAstronomyRepository()
        mock.enqueue(
            AstronomyPageResult(
                items: [makeAstronomy(date: "2024-06-19", title: "Page 1")],
                source: .network,
                hasMore: true,
                fallbackError: nil
            )
        )
        mock.enqueue(
            AstronomyPageResult(
                items: [makeAstronomy(date: "2024-06-18", title: "Page 2")],
                source: .network,
                hasMore: true,
                fallbackError: nil
            )
        )

        let viewModel = AstronomyListViewModel(repository: mock)
        let delegate = MockFeedDelegate()
        viewModel.delegate = delegate

        await viewModel.refresh()
        viewModel.loadNextPageIfNeeded(currentRow: 0)

        // Wait for async pagination
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.astronomies.count, 2)
        XCTAssertEqual(viewModel.astronomies.last?.title, "Page 2")
        XCTAssertEqual(mock.loadPageCallCount, 2)
        XCTAssertGreaterThanOrEqual(delegate.feedUpdateCount, 2)
    }

    func testRefreshClearsFeedBeforeReload() async {
        let mock = MockAstronomyRepository()
        mock.enqueue(
            AstronomyPageResult(
                items: [makeAstronomy(date: "2024-06-19", title: "First")],
                source: .network,
                hasMore: true,
                fallbackError: nil
            )
        )
        mock.enqueue(
            AstronomyPageResult(
                items: [makeAstronomy(date: "2024-06-18", title: "Second")],
                source: .network,
                hasMore: false,
                fallbackError: nil
            )
        )

        let viewModel = AstronomyListViewModel(repository: mock)
        await viewModel.refresh()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.astronomies.count, 1)
        XCTAssertEqual(viewModel.astronomies.first?.title, "Second")
    }

    func testRefreshShowsFailedStateWhenEmpty() async {
        let mock = MockAstronomyRepository()
        mock.enqueue(
            AstronomyPageResult(
                items: [],
                source: .offlineCache,
                hasMore: false,
                fallbackError: "No connection"
            )
        )

        let viewModel = AstronomyListViewModel(repository: mock)
        await viewModel.refresh()

        XCTAssertEqual(viewModel.loadingState, .failed("No connection"))
        XCTAssertTrue(viewModel.astronomies.isEmpty)
    }
}

// MARK: - Mocks

private actor MockAstronomyRepository: AstronomyRepositoryProtocol {
    private var results: [AstronomyPageResult] = []
    private(set) var loadPageCallCount = 0

    func enqueue(_ result: AstronomyPageResult) {
        results.append(result)
    }

    func loadPage(daysAlreadyLoaded: Int, oldestLoadedDate: String?) async -> AstronomyPageResult {
        loadPageCallCount += 1
        if loadPageCallCount <= results.count {
            return results[loadPageCallCount - 1]
        }
        return AstronomyPageResult(items: [], source: .network, hasMore: false, fallbackError: nil)
    }
}

@MainActor
private final class MockFeedDelegate: AstronomyListViewModelDelegate {
    var feedUpdateCount = 0
    var lastAnimatingDifferences: Bool?

    func didUpdateFeed(animatingDifferences: Bool) {
        feedUpdateCount += 1
        lastAnimatingDifferences = animatingDifferences
    }

    func didUpdateImage(for date: String, image: UIImage) {}
    func didUpdateLoadingState() {}
    func didUpdateLoadingMore(_ isLoading: Bool) {}
    func didUpdateDataSourceBanner(message: String?) {}
    func didUpdateEndOfFeed(_ isAtEnd: Bool) {}
}

private func makeAstronomy(date: String, title: String) -> Astronomy {
    Astronomy(
        copyright: nil,
        date: date,
        explanation: "Explanation",
        hdurl: nil,
        mediaType: "image",
        serviceVersion: "v1",
        title: title,
        url: "https://example.com/\(date).jpg"
    )
}

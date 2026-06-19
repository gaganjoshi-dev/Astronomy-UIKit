//
//  AstronomyTests.swift
//  AstronomyTests
//

import XCTest
import CoreData
@testable import Astronomy

final class AstronomyDecodingTests: XCTestCase {

    func testDecodesImageAPOD() throws {
        let json = """
        {
          "copyright": "Yuri Beletsky",
          "date": "2024-10-11",
          "explanation": "Sample explanation",
          "hdurl": "https://apod.nasa.gov/apod/image/2410/eclipse_02.jpg",
          "media_type": "image",
          "service_version": "v1",
          "title": "Ring of Fire",
          "url": "https://apod.nasa.gov/apod/image/2410/eclipse_02_1024.jpg"
        }
        """.data(using: .utf8)!

        let astronomy = try JSONDecoder().decode(Astronomy.self, from: json)
        XCTAssertEqual(astronomy.date, "2024-10-11")
        XCTAssertTrue(astronomy.isImage)
    }

    func testDecodesVideoAPOD() throws {
        let json = """
        {
          "date": "2024-01-01",
          "explanation": "Video sample",
          "media_type": "video",
          "service_version": "v1",
          "title": "Video Title",
          "url": "https://www.youtube.com/watch?v=abc"
        }
        """.data(using: .utf8)!

        let astronomy = try JSONDecoder().decode(Astronomy.self, from: json)
        XCTAssertFalse(astronomy.isImage)
        XCTAssertNil(astronomy.hdurl)
    }
}

final class AstronomyDateHelperTests: XCTestCase {

    func testFirstPageRangeStartsAtToday() {
        let range = AstronomyDateHelper.pageRange(daysAlreadyLoaded: 0, pageSize: 15, maxHistoryDays: 100)
        XCTAssertNotNil(range)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let today = formatter.string(from: Date())

        XCTAssertEqual(range?.end, today)
    }

    func testHasMorePagesUntilHistoryLimit() {
        XCTAssertTrue(AstronomyDateHelper.hasMorePages(daysLoaded: 0, maxHistoryDays: 100))
        XCTAssertTrue(AstronomyDateHelper.hasMorePages(daysLoaded: 90, maxHistoryDays: 100))
        XCTAssertFalse(AstronomyDateHelper.hasMorePages(daysLoaded: 100, maxHistoryDays: 100))
    }
}

final class AstronomyRepositoryTests: XCTestCase {

    func testFallsBackToCoreDataWhenNetworkFails() async throws {
        let container = makeInMemoryContainer()
        let persistence = AstronomyPersistenceStore(container: container)

        let cached = Astronomy(
            copyright: nil,
            date: "2024-01-01",
            explanation: "Cached item",
            hdurl: nil,
            mediaType: "image",
            serviceVersion: "v1",
            title: "Cached",
            url: "https://example.com/image.jpg"
        )
        try await persistence.save([cached])

        let repository = AstronomyRepository(
            networkService: FailingNetworkService(),
            persistenceStore: persistence,
            historyDays: 100
        )

        let result = await repository.loadPage(daysAlreadyLoaded: 0, oldestLoadedDate: nil)
        XCTAssertEqual(result.source, .offlineCache)
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.first?.title, "Cached")
    }

    func testPaginatedCacheFetchReturnsOlderItems() async throws {
        let container = makeInMemoryContainer()
        let persistence = AstronomyPersistenceStore(container: container)

        let newer = makeAstronomy(date: "2024-02-02", title: "Newer")
        let older = makeAstronomy(date: "2024-02-01", title: "Older")
        try await persistence.save([newer, older])

        let firstPage = await persistence.fetchAstronomies(before: nil, limit: 1)
        XCTAssertEqual(firstPage.first?.title, "Newer")

        let secondPage = await persistence.fetchAstronomies(before: firstPage.last?.date, limit: 1)
        XCTAssertEqual(secondPage.first?.title, "Older")
    }
}

private final class FailingNetworkService: AstronomyNetworkServiceProtocol {
    func getAstronomies(from startDate: String, to endDate: String) async throws -> [Astronomy] {
        throw URLError(.notConnectedToInternet)
    }
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
        url: "https://example.com/image.jpg"
    )
}

private func makeInMemoryContainer() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "Astronomy")
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { _, error in
        if let error { fatalError("In-memory store failed: \(error)") }
    }
    return container
}

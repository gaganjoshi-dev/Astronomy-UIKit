//
//  AstronomyPersistenceStore.swift
//  Astronomy
//

import CoreData

/// Thread-safe Core Data access using Swift's `actor` isolation.
actor AstronomyPersistenceStore {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func save(_ astronomies: [Astronomy]) async throws {
        guard !astronomies.isEmpty else { return }

        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await context.perform {
            let dates = astronomies.map(\.date)
            let fetchRequest = AstronomyEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date IN %@", dates)

            let existing = try context.fetch(fetchRequest)
            var existingByDate: [String: AstronomyEntity] = [:]
            existingByDate.reserveCapacity(existing.count)
            for entity in existing {
                guard let date = entity.date else { continue }
                existingByDate[date] = entity
            }

            let fetchedAt = Date()
            for astronomy in astronomies {
                let entity = existingByDate[astronomy.date] ?? AstronomyEntity(context: context)
                entity.update(from: astronomy, fetchedAt: fetchedAt)
            }

            if context.hasChanges {
                try context.save()
            }

            DiagnosticsLogger.logCoreDataSave(count: astronomies.count, dates: dates)
        }
    }

    /// Fetches a page of cached items, optionally older than `beforeDate` (exclusive).
    func fetchAstronomies(before beforeDate: String?, limit: Int) async -> [Astronomy] {
        let context = container.newBackgroundContext()

        return await context.perform {
            let request = AstronomyEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = limit

            if let beforeDate {
                request.predicate = NSPredicate(format: "date < %@", beforeDate)
            }

            guard let entities = try? context.fetch(request) else { return [] }
            let items = entities.map { $0.toDomain() }
            DiagnosticsLogger.logCoreDataFetch(before: beforeDate, limit: limit, items: items)
            return items
        }
    }
}

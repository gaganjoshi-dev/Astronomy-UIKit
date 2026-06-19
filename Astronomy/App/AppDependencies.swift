//
//  AppDependencies.swift
//  Astronomy
//

import Foundation

/// Composition root — creates and holds app-wide service dependencies.
final class AppDependencies {

    let coreDataStack: CoreDataStack

    private let networkService: AstronomyNetworkServiceProtocol
    private let persistenceStore: AstronomyPersistenceStore

    lazy var astronomyRepository: AstronomyRepository = {
        AstronomyRepository(
            networkService: networkService,
            persistenceStore: persistenceStore
        )
    }()

    init(coreDataStack: CoreDataStack = CoreDataStack()) {
        self.coreDataStack = coreDataStack
        self.networkService = AstronomyService()
        self.persistenceStore = AstronomyPersistenceStore(container: coreDataStack.container)
    }
}

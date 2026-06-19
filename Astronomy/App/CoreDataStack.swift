//
//  CoreDataStack.swift
//  Astronomy
//

import CoreData

/// Owns the Core Data persistent container and store loading.
final class CoreDataStack {

    let container: NSPersistentContainer

    init(modelName: String = "Astronomy", inMemory: Bool = false) {
        container = NSPersistentContainer(name: modelName)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                AppLogger.app.error("Core Data store failed to load: \(error.localizedDescription)")
            } else {
                AppLogger.app.info("Core Data store loaded")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

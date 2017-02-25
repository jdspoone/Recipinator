/*

  Written by Jeff Spooner

*/

import CoreData


class CoreDataController: NSObject
  {

    private let managedObjectContext: NSManagedObjectContext


    var documentsDirectory: URL
      { return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! }


    var dataStoreType: String
      { return NSSQLiteStoreType }


    var dataStoreURL: URL
      { return documentsDirectory.appendingPathComponent("RecipeBook.sqlite") }

    var temporaryDataStoreURL: URL
      { return documentsDirectory.appendingPathComponent("TemporaryRecipeBook.sqlite") }


    var managedObjectModel: NSManagedObjectModel
      { return NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "RecipeBook", withExtension: "momd")!)! }


    override init()
      {
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        super.init()
      }


    func mappingModelWithName(name: String) -> NSMappingModel?
      {
        return NSMappingModel(contentsOf: Bundle.main.url(forResource: name, withExtension: "cdm")!)
      }


    func getManagedObjectContext() -> NSManagedObjectContext
      {
        // If the managed object context's persistent store coordinator is non-nil, we've no more work to do
        if let _ = managedObjectContext.persistentStoreCoordinator {
          return managedObjectContext
        }

        // Otherwise, we need to configure an attach the persistent store to the managed object context
        // Get the persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
          // If there currently is a file at the datastore path
          if FileManager.default.fileExists(atPath: dataStoreURL.path) {

            // Get the persistent store's metadata
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: dataStoreURL, options: nil)

            // Determine if we need to migrate
            let compatible = managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata)

            // If a migration is needed
            if compatible == false {

              // Get the source model
              let sourceModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: sourceMetadata)!

              // Get the destination model
              let destinationModel = managedObjectModel

              // Get the mapping model between the source and destination models
              let mappingModel = mappingModelWithName(name: "v1")

              // Create a migration manager
              let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)

              // Ensure there is no file at the temporary data store url
              if FileManager.default.fileExists(atPath: temporaryDataStoreURL.path) {
                try FileManager.default.removeItem(at: temporaryDataStoreURL)
              }

              // Migrate the datastore
              try migrationManager.migrateStore(from: dataStoreURL, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: temporaryDataStoreURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)

              // Move the migrated datastore to from the temporary location to the primary location
              try FileManager.default.removeItem(at: dataStoreURL)
              try FileManager.default.moveItem(at: temporaryDataStoreURL, to: dataStoreURL)
            }

          }

          // Attempt to add the persistent store
          try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dataStoreURL, options: nil)
        }
        catch let e {
          fatalError("error: \(e)")
        }

        // Attach the persistent store coordinator to the managed object context
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        // Return the managed object context
        return managedObjectContext
      }

  }

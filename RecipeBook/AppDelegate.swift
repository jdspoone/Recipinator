/*
  
  Written by Jeff Spooner

*/

import UIKit
import CoreData


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
  {

    var window: UIWindow?

    var managedObjectContext: NSManagedObjectContext


    class var applicationDocumentsDirectory: URL
      { return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! }


    class var dataStoreURL: URL
      { return self.applicationDocumentsDirectory.appendingPathComponent("RecipeBook.sqlite") }


    class var managedObjectModel: NSManagedObjectModel
      { return NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "RecipeBook", withExtension: "momd")!)! }



    override init()
      {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: AppDelegate.managedObjectModel)

        do {
          // Create an options dictionary to enable automatic migration
          let options = [
              NSMigratePersistentStoresAutomaticallyOption: true,
              NSInferMappingModelAutomaticallyOption: true
            ]

          // Attempt to add the persistent store, using automatic migration if necessary
          try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: AppDelegate.dataStoreURL, options: options)
        }
        catch let e {
          fatalError("error: \(e)")
        }

        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
      }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
      {
        // Instantiate the main window
        window = UIWindow(frame: UIScreen.main.bounds)

        // Embed the recipe table view controller in a navigation view controller, and set that as the root view controller
        let navigationViewController = UINavigationController(rootViewController: SearchViewController(context: managedObjectContext))
        navigationViewController.navigationBar.isTranslucent = false
        self.window!.rootViewController = navigationViewController

        // Make the window key and visible
        window!.makeKeyAndVisible()

        return true
      }

  }

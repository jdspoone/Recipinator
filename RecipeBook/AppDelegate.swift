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


    class var applicationDocumentsDirectory: NSURL
      { return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last! }


    class var dataStoreURL: NSURL
      { return self.applicationDocumentsDirectory.URLByAppendingPathComponent("RecipeBook.sqlite") }


    class var managedObjectModel: NSManagedObjectModel
      { return NSManagedObjectModel(contentsOfURL: NSBundle.mainBundle().URLForResource("RecipeBook", withExtension: "momd")!)! }



    override init()
      {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: AppDelegate.managedObjectModel)

        do {
          if NSFileManager.defaultManager().fileExistsAtPath(AppDelegate.dataStoreURL.path!) {
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: AppDelegate.dataStoreURL, options: nil)

            // If the mom has changed since last time, just delete the old one
            if AppDelegate.managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetadata) == false {
              try NSFileManager.defaultManager().removeItemAtURL(AppDelegate.dataStoreURL)
            }
          }

          // Add the pstore
          try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: AppDelegate.dataStoreURL, options: nil)
        }
        catch let e {
          fatalError("error: \(e)")
        }

        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
      }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
      {
        // Instantiate the main window
        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        // Embed the recipe table view controller in a navigation view controller, and set that as the root view controller
        let navigationViewController = UINavigationController(rootViewController: SearchViewController(context: managedObjectContext))
        navigationViewController.navigationBar.translucent = false
        self.window!.rootViewController = navigationViewController

        // Make the window key and visible
        window!.makeKeyAndVisible()

        return true
      }

  }
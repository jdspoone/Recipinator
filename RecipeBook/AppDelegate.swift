/*
  
  Written by Jeff Spooner

*/

import UIKit
import CoreData


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
  {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
      {
        // Instantiate the main window
        window = UIWindow(frame: UIScreen.main.bounds)

        // Create a CoreDataController and get the managed object context
        let coreDataController = CoreDataController()
        let managedObjectContext = coreDataController.getManagedObjectContext()

        // Embed the recipe table view controller in a navigation view controller, and set that as the root view controller
        let navigationViewController = UINavigationController(rootViewController: SearchViewController(context: managedObjectContext))
        navigationViewController.navigationBar.isTranslucent = false
        self.window!.rootViewController = navigationViewController

        // Make the window key and visible
        window!.makeKeyAndVisible()

        return true
      }

  }

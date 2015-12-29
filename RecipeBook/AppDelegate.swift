/*

*/

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
  {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
      {
        // Instantiate the main window
        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        // Set the window's root view controller
        self.window!.rootViewController = UITableViewController(style: .Plain)

        // Make the window key and visible
        window!.makeKeyAndVisible()

        return true
      }

  }
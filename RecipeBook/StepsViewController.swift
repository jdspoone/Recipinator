/*

  Written by Jeff Spooner

*/


import UIKit
import CoreData


class StepsViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
  {

    var observations =  Set<Observation>()

    var steps: [Step]
    var initialIndex: Int
    var initialEditingState: Bool
    var managedObjectContext: NSManagedObjectContext
    var completion: () -> Void

    var pageViewController: UIPageViewController

    var activeViewController: BaseViewController?
      {
        get { return pageViewController.viewControllers!.first as? BaseViewController }
      }

    var saveButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!


    init(steps: [Step], index: Int, editing: Bool, context: NSManagedObjectContext, completion: () -> Void)
      {
        self.steps = steps
        self.initialIndex = index
        self.initialEditingState = editing
        self.managedObjectContext = context
        self.completion = completion

        self.pageViewController = UIPageViewController(transitionStyle: .PageCurl, navigationOrientation: .Horizontal, options: nil)

        super.init(nibName: nil, bundle: nil)

        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
      }


    // MARK: - UIViewController

    required init?(coder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        // Create the root view
        let window = UIApplication.sharedApplication().windows.first!
        let navigationBar = (window.rootViewController! as! UINavigationController).navigationBar

        let offset = navigationBar.frame.origin.y + navigationBar.frame.height

        let width = window.frame.width
        let height = window.frame.height - offset

        // Configure the root view
        view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.backgroundColor = UIColor.whiteColor()
        view.opaque = true

        // Configure the page view controller
        addChildViewController(pageViewController)
        let pageView = pageViewController.view
        pageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView)

        // Configure the layout bindings for the page view controller
        pageView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        pageView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        pageView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        pageView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

        // Create the navigation bar buttons
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: #selector(BaseViewController.save(_:)))
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(BaseViewController.done(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Initialize the editing state
        setEditing(initialEditingState, animated: true)

        // Set the view controller of the page view controller
        let viewController = StepViewController(step: steps[initialIndex], editing: false, context: managedObjectContext)
          { (step: Step) in
            if self.managedObjectContext.hasChanges {
              do { try self.managedObjectContext.save() }
              catch { fatalError("failed to save") }
            }
          }
        pageViewController.setViewControllers([viewController], direction: .Forward, animated: true, completion: nil)
      }


    override func viewWillAppear(animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom notifications
        observations = [
          Observation(source: self.activeViewController!, keypaths: ["activeSubview"], options: NSKeyValueObservingOptions(), block:
            { (change: [String : AnyObject]?) -> Void in
              if let _ = self.activeViewController?.activeSubview {
                self.navigationItem.rightBarButtonItem = self.doneButton
              }
              else {
                self.navigationItem.rightBarButtonItem = self.saveButton
              }
            })
        ]
      }


    override func viewWillDisappear(animated: Bool)
      {
        super.viewWillAppear(animated)

        // De-register custom notifications
        observations.removeAll()

        // Execute the completion block
        completion()
      }



    override func setEditing(editing: Bool, animated: Bool)
      {
        willChangeValueForKey("editing")
        super.setEditing(editing, animated: animated)
        didChangeValueForKey("editing")

        navigationItem.setHidesBackButton(editing, animated: false)
        navigationItem.rightBarButtonItem = editing ? saveButton : editButtonItem()

        activeViewController?.setEditing(editing, animated: animated)
      }


    // MARK: - UIPageViewControllerDataSource

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
      {
        // Get the currently displated step view controller
        let stepViewController = viewController as! StepViewController
        let index = Int(stepViewController.step.number)

        // As long as it isn't for the final step
        if (index > 0) {
          // Return a step view controller for the next step
          return StepViewController(step: steps[index - 1], editing: editing, context: managedObjectContext)
            { (step: Step) in
              if self.managedObjectContext.hasChanges {
                do { try self.managedObjectContext.save() }
                catch { fatalError("failed to save") }
              }
            }
        }

        return nil
      }


    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
      {
        // Get the currently displated step view controller
        let stepViewController = viewController as! StepViewController
        let index = Int(stepViewController.step.number)

        // As long as it isn't for the final step
        if (index < steps.count - 1) {
          // Return a step view controller for the next step
          return StepViewController(step: steps[index + 1], editing: editing, context: managedObjectContext)
            { (step: Step) in
              if self.managedObjectContext.hasChanges {
                do { try self.managedObjectContext.save() }
                catch { fatalError("failed to save") }
              }
            }
        }

        return nil
      }


    // MARK: - UIPageViewControllerDelegate

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
      {
        // De-register custom notifications
        observations.removeAll()

        // Register custom notifications
        observations = [
          Observation(source: self.activeViewController!, keypaths: ["activeSubview"], options: NSKeyValueObservingOptions(), block:
            { (change: [String : AnyObject]?) -> Void in
              if let _ = self.activeViewController?.activeSubview {
                self.navigationItem.rightBarButtonItem = self.doneButton
              }
              else {
                self.navigationItem.rightBarButtonItem = self.saveButton
              }
            })
        ]

        activeViewController?.setEditing(editing, animated: false)
      }



    // MARK: - Actions

    func save(sender: AnyObject?)
      {
        activeViewController!.save(sender)
        setEditing(false, animated: true)
      }


    func done(sender: AnyObject?)
      {
        activeViewController!.done(sender)
      }

  }

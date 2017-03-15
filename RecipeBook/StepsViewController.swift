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
    var completion: (Step) -> Void

    var pageViewController: UIPageViewController

    var activeViewController: StepViewController?
      {
        get { return pageViewController.viewControllers!.first as? StepViewController }
      }

    var endEditingButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!


    init(steps: [Step], index: Int, editing: Bool, context: NSManagedObjectContext, completion: @escaping (Step) -> Void)
      {
        self.steps = steps
        self.initialIndex = index
        self.initialEditingState = editing
        self.managedObjectContext = context
        self.completion = completion

        self.pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)

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
        let window = UIApplication.shared.windows.first!
        let navigationBar = (window.rootViewController! as! UINavigationController).navigationBar

        let offset = navigationBar.frame.origin.y + navigationBar.frame.height

        let width = window.frame.width
        let height = window.frame.height - offset

        // Configure the root view
        view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.backgroundColor = UIColor.white
        view.isOpaque = true

        // Configure the page view controller
        addChildViewController(pageViewController)
        let pageView = pageViewController.view
        pageView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView!)

        // Configure the layout bindings for the page view controller
        pageView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pageView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        pageView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pageView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Create the navigation bar buttons
        endEditingButton = UIBarButtonItem(title: NSLocalizedString("END EDITING", comment: ""), style: .plain, target: self, action: #selector(self.endEditing(_:)))
        doneButton = UIBarButtonItem(title: NSLocalizedString("DONE", comment: ""), style: .plain, target: self, action: #selector(self.done(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Initialize the editing state
        setEditing(initialEditingState, animated: true)

        // Set the view controller of the page view controller
        let initialStep = steps[initialIndex]
        let viewController = StepViewController(step: initialStep, editing: isEditing, context: managedObjectContext)
        pageViewController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)

        // Set the title of the navigation item
        navigationItem.title = NSLocalizedString("STEP", comment: "") + " \(initialStep.number + 1)"
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom notifications
        observations = [
          Observation(source: self.activeViewController!, keypaths: ["activeSubview"], options: NSKeyValueObservingOptions(), block:
            { (change: [NSKeyValueChangeKey : Any]?) -> Void in
              if let _ = self.activeViewController?.activeSubview {
                self.navigationItem.rightBarButtonItem = self.doneButton
                self.navigationItem.hidesBackButton = true
              }
              else {
                self.navigationItem.rightBarButtonItem = self.endEditingButton
                self.navigationItem.hidesBackButton = false
              }
            })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // De-register custom notifications
        observations.removeAll()

        // If we're currently presenting a step view controller, and we're moving to the parent view controller
        if let activeViewController = activeViewController, isMovingToParentViewController {

          // Have it end editing
          activeViewController.endEditing(self)

          // Execute our completion callback
          completion(activeViewController.step)
        }
      }



    override func setEditing(_ editing: Bool, animated: Bool)
      {
        willChangeValue(forKey: "editing")
        super.setEditing(editing, animated: animated)
        didChangeValue(forKey: "editing")

        navigationItem.rightBarButtonItem = editing ? endEditingButton : editButtonItem

        activeViewController?.setEditing(editing, animated: animated)
      }


    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
      {
        // Get the currently displated step view controller
        let stepViewController = viewController as! StepViewController
        let index = Int(stepViewController.step.number)

        // As long as it isn't for the final step
        if index > 0 {
          // Return a step view controller for the next step
          return StepViewController(step: steps[index - 1], editing: isEditing, context: managedObjectContext)
        }

        return nil
      }


    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
      {
        // Get the currently displated step view controller
        let stepViewController = viewController as! StepViewController
        let index = Int(stepViewController.step.number)

        // As long as it isn't for the final step
        if index < steps.count - 1 {
          // Return a step view controller for the next step
          return StepViewController(step: steps[index + 1], editing: isEditing, context: managedObjectContext)
        }

        return nil
      }


    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
      {
        // As long as we're currently presenting a step view controller
        if let activeViewController = activeViewController, activeViewController.isEditing {

          // Have it end editing
          activeViewController.endEditing(self)

          // Execute our completion callback
          completion(activeViewController.step)
        }
      }


    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
      {
        // De-register custom notifications for the previous StepViewController
        observations.removeAll()

        // Register custom notifications for the new StepViewController
        observations = [
          Observation(source: self.activeViewController!, keypaths: ["activeSubview"], options: NSKeyValueObservingOptions(), block:
            { (change: [NSKeyValueChangeKey : Any]?) -> Void in
              if let _ = self.activeViewController?.activeSubview {
                self.navigationItem.rightBarButtonItem = self.doneButton
              }
              else {
                self.navigationItem.rightBarButtonItem = self.endEditingButton
              }
            })
        ]

        // Update the editing state of the active view controller
        activeViewController!.setEditing(isEditing, animated: false)

        // Update the navigation controller's title
        navigationItem.title = NSLocalizedString("STEP", comment: "") + " \(activeViewController!.step.number + 1)"
      }



    // MARK: - Actions

    func endEditing(_ sender: AnyObject?)
      {
        // Set the editing state to false
        setEditing(false, animated: true)

        // Have the active view controller end editing
        activeViewController!.endEditing(sender)
      }


    func done(_ sender: AnyObject?)
      {
        activeViewController!.done(sender)
      }

  }

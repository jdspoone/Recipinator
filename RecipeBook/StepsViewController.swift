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


    init(steps: [Step], index: Int, editing: Bool, context: NSManagedObjectContext, completion: @escaping () -> Void)
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
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .plain, target: self, action: #selector(BaseViewController.save(_:)))
        doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .plain, target: self, action: #selector(BaseViewController.done(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Initialize the editing state
        setEditing(initialEditingState, animated: true)

        // Set the view controller of the page view controller
        let viewController = StepViewController(step: steps[initialIndex], editing: isEditing, context: managedObjectContext)
          { (step: Step) in
            if self.managedObjectContext.hasChanges {
              do { try self.managedObjectContext.save() }
              catch { fatalError("failed to save") }
            }
          }
        pageViewController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
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
              }
              else {
                self.navigationItem.rightBarButtonItem = self.saveButton
              }
            })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // De-register custom notifications
        observations.removeAll()

        // Execute the completion block as long as we're not presenting another view controller
        if presentedViewController == nil {
          completion()
        }
      }



    override func setEditing(_ editing: Bool, animated: Bool)
      {
        willChangeValue(forKey: "editing")
        super.setEditing(editing, animated: animated)
        didChangeValue(forKey: "editing")

        navigationItem.setHidesBackButton(editing, animated: false)
        navigationItem.rightBarButtonItem = editing ? saveButton : editButtonItem

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
            { (step: Step) in
              if self.managedObjectContext.hasChanges {
                do { try self.managedObjectContext.save() }
                catch { fatalError("failed to save") }
              }
            }
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
                self.navigationItem.rightBarButtonItem = self.saveButton
              }
            })
        ]

        activeViewController?.setEditing(isEditing, animated: false)
      }



    // MARK: - Actions

    func save(_ sender: AnyObject?)
      {
        activeViewController!.save(sender)
        setEditing(false, animated: true)
      }


    func done(_ sender: AnyObject?)
      {
        activeViewController!.done(sender)
      }

  }

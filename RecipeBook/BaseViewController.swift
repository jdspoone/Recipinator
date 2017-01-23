/*

  Written by Jeff Spooner

  UIViewController subclass which programmatically creates a root view instance with a child scroll view and
  manages their layout bindings, as well as creating save and done buttons to be displayed in the navigation item.
  This class maintains a reference to an optional active subview, assumed to be text based, and handles automatic 
  scrolling of the primary scroll view to ensure the active subview will be visible when the keyboard appears.

*/

import UIKit


class BaseViewController: UIViewController
  {

    var scrollView: UIScrollView!
    var scrollViewBottomConstraint: NSLayoutConstraint!
    var scrollViewHeightConstraint: NSLayoutConstraint?

    var saveButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!

    var defaultEditingState: Bool = true

    var activeSubview: UIView?
      {
        willSet {
          assert(editing, "unexpected state")
          willChangeValueForKey("activeSubview")
        }

        didSet {
          assert(editing, "unexpected state")
          didChangeValueForKey("activeSubview")

          if let _ = activeSubview {
            navigationItem.rightBarButtonItem = doneButton
          }
          else {
            navigationItem.rightBarButtonItem = saveButton
          }
        }
      }


    init(editing: Bool)
      {
        self.defaultEditingState = editing

        super.init(nibName: nil, bundle: nil)
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        // Create the root view
        let windowFrame = (UIApplication.sharedApplication().windows.first?.frame)!

        let width = windowFrame.width
        let height = windowFrame.height

        view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))

        // Create the scroll view
        scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.backgroundColor = UIColor.whiteColor()
        scrollView.opaque = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Configure the layout bindings for the scroll view
        scrollView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        scrollView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        scrollView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true

        scrollViewBottomConstraint = scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        scrollViewBottomConstraint.active = true

        // Create the navigation bar buttons
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: #selector(BaseViewController.save(_:)))
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(BaseViewController.done(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        setEditing(defaultEditingState, animated: true)
      }


    override func viewWillAppear(animated: Bool)
      {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.keyboardWillMove(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.keyboardWillMove(_:)), name: UIKeyboardWillHideNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.deviceOrientationDidChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
      }


    override func viewWillDisappear(animated: Bool)
      {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
      }


    override func setEditing(editing: Bool, animated: Bool)
      {
        willChangeValueForKey("editing")
        super.setEditing(editing, animated: animated)
        didChangeValueForKey("editing")

        navigationItem.setHidesBackButton(editing, animated: false)
        navigationItem.rightBarButtonItem = editing ? saveButton : editButtonItem()
      }


    // MARK: - NSNotificationCenter

    func keyboardWillMove(notification: NSNotification)
      {
        if let subview = activeSubview {

          // Sanity check
          assert(subview.isKindOfClass(UITextField) || subview.isKindOfClass(UITextView))

          // Get the frames of the keyboard and subview
          let navFrame = navigationController!.navigationBar.frame
          let frame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
          let keyboardFrame = CGRect(x: frame.origin.x, y: frame.origin.y - (navFrame.origin.y + navFrame.height), width: frame.width, height: frame.height)
          let subviewFrame = subview.superview!.convertRect(subview.frame, toView: view)

          // Get the overlap between the keyboard and subview
          let overlapRect = subviewFrame.intersect(keyboardFrame)

          // Get the duration of the keyboard animation
          let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double

          // If the keyboard is about to appear
          if notification.name == UIKeyboardWillShowNotification {

            // Disable scrolling while we're editing text
            scrollView.scrollEnabled = false

            // If the keyboard will overlap with the active subview
            if overlapRect.height > 0 {

              // Deactivate the scroll view's bottom constraint
              scrollViewBottomConstraint.active = false

              // Set and activate the scroll view's height constraint
              scrollViewHeightConstraint = scrollView.heightAnchor.constraintEqualToConstant(scrollView.frame.height - keyboardFrame.height)
              scrollViewHeightConstraint!.active = true

              // Update the scroll view's frame and content offset in an animation block
              UIView.animateWithDuration(duration, animations:
                  { () -> Void in
                    self.scrollView.frame = CGRect(x: self.scrollView.frame.origin.x, y: self.scrollView.frame.origin.y, width: self.scrollView.frame.width, height: self.scrollView.frame.height - keyboardFrame.height)
                    self.scrollView.contentOffset = CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y + subviewFrame.origin.y + subviewFrame.height - self.scrollView.frame.height)
                  })
            }
          }

          // Otherwise if the keyboard is about to disappear
          else if notification.name == UIKeyboardWillHideNotification {

            // Re-enable scrolling
            scrollView.scrollEnabled = true

            // Update the scroll view's layout constraints
            scrollViewHeightConstraint?.active = false
            scrollViewBottomConstraint.active = true

            // Animate the scroll view's frame
            UIView.animateWithDuration(duration, animations:
                { () -> Void in
                  self.scrollView.frame = CGRect(x: self.scrollView.frame.origin.x, y: self.scrollView.frame.origin.y, width: self.scrollView.frame.width, height: self.view.frame.height)
                })
          }
        }
      }


    func deviceOrientationDidChange(notification: NSNotification)
      {
        scrollView.contentSize = CGSize(width: view.frame.width, height: scrollView.contentSize.height)
      }


    // MARK: Actions

    func save(sender: AnyObject?)
      {
        activeSubview?.resignFirstResponder()

        setEditing(false, animated: true)
      }


    func done(sender: AnyObject?)
      {
        activeSubview!.resignFirstResponder()
      }

  }
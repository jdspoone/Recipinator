/*

  Written by Jeff Spooner

*/

import UIKit


class ScrollingViewController: UIViewController
  {

    var scrollView: UIScrollView!

    var saveButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!

    var defaultEditingState: Bool = true

    var activeSubview: UIView?
      {
        didSet {
          assert(editing, "unexpected state")

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
        let navigationBarFrame = navigationController!.navigationBar.frame

        let width = windowFrame.width
        let height = windowFrame.height - (navigationBarFrame.origin.y + navigationBarFrame.height)

        view = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)))

        // Create the scroll view
        scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.backgroundColor = UIColor.whiteColor()
        scrollView.opaque = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Configure the layout bindings for the scroll view
        scrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        scrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        scrollView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true

        // Create the navigation bar buttons
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "save:")
        doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "done:")
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        setEditing(defaultEditingState, animated: true)
      }


    override func viewWillAppear(animated: Bool)
      {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillMove:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillMove:", name: UIKeyboardWillHideNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceOrientationDidChange:", name: UIDeviceOrientationDidChangeNotification, object: nil)
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

        if editing {
          navigationItem.setHidesBackButton(true, animated: false)
          navigationItem.rightBarButtonItem = saveButton
        }
        else {
          activeSubview?.resignFirstResponder()
          navigationItem.setHidesBackButton(false, animated: false)
          navigationItem.rightBarButtonItem = editButtonItem()
        }
      }


    // MARK: - NSNotificationCenter

    func keyboardWillMove(notification: NSNotification)
      {
        if let subview = activeSubview {

          // Sanity check
          assert(subview.isKindOfClass(UITextField) || subview.isKindOfClass(UITextView))

          // Get the frame of the keyboard
          let frame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
          let keyboardFrame = CGRect(x: frame.origin.x, y: scrollView.contentSize.height - frame.height, width: frame.width, height: frame.height)

          // Get the frame of the subview
          var subviewFrame: CGRect
          // If the view is a direct descendant of the scroll view, its frame is ready to use
          if scrollView.subviews.contains(subview) {
            subviewFrame = subview.frame
          }
          // Otherwise it is an indirect descendant of the scroll view, and it needs to be converted
          else {
            subviewFrame = subview.convertRect(subview.frame, toView: scrollView)
          }

          // Get the overlap between the keyboard and subview
          let overlapRect = subviewFrame.intersect(keyboardFrame)

          // If there is any overlap
          if notification.name == UIKeyboardWillShowNotification && overlapRect.height > 0 {
            let duration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

            // Unhook the bottom of the scroll view from its parent view
            scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = false

            // Shrink the scroll view
            UIView.animateWithDuration(duration, animations:
                { () -> Void in
                  // Set the content inset of the scroll view
                  self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
                  // Scroll so the textfield is visible
                  self.scrollView.scrollRectToVisible(CGRect(x: self.scrollView.frame.origin.x, y: subviewFrame.origin.y, width: self.scrollView.frame.width, height: subviewFrame.height), animated: true)
                })
          }
          else {
            // Restore the scroll view to its original size
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
          }
        }
      }


    func deviceOrientationDidChange(notification: NSNotification)
      {
        scrollView.contentSize = CGSize(width: view.frame.width, height: scrollView.contentSize.height)
      }


    // MARK: Actions

    func save(sender: UIBarButtonItem)
      {
        setEditing(false, animated: true)
      }


    func done(sender: UIBarButtonItem)
      {
        assert(activeSubview != nil, "unexpected state - no active subview")
        activeSubview?.resignFirstResponder()
      }

  }
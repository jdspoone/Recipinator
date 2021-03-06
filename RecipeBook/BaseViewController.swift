/*

  Written by Jeff Spooner

  UIViewController subclass which programmatically creates a root view instance with a child scroll view and
  manages their layout bindings, as well as creating save and done buttons to be displayed in the navigation item.
  This class maintains a reference to an optional active subview, assumed to be text based, and handles automatic 
  scrolling of the primary scroll view to ensure the active subview will be visible when the keyboard appears.

*/

import UIKit
import CoreData


class BaseViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate
  {

    var observations = Set<Observation>()

    var managedObjectContext: NSManagedObjectContext

    var scrollView: UIScrollView!
    var scrollViewSubviews = Set<UIView>()
    var scrollViewBottomConstraint: NSLayoutConstraint!
    var scrollViewHeightConstraint: NSLayoutConstraint?

    var endEditingButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!

    var defaultEditingState: Bool = true

    var activeSubview: UIView?
      {
        willSet {
          assert(isEditing, "unexpected state")
          willChangeValue(forKey: "activeSubview")
        }

        didSet {
          assert(isEditing, "unexpected state")
          didChangeValue(forKey: "activeSubview")

          if let _ = activeSubview {
            navigationItem.rightBarButtonItem = doneButton
            navigationItem.hidesBackButton = true
          }
          else {
            navigationItem.rightBarButtonItem = endEditingButton
            navigationItem.hidesBackButton = false
          }
        }
      }


    // MARK: -

    init(editing: Bool, context: NSManagedObjectContext)
      {
        self.defaultEditingState = editing
        self.managedObjectContext = context

        super.init(nibName: nil, bundle: nil)
      }


    func addSubviewToScrollView(_ view: UIView)
      {
        scrollViewSubviews.insert(view)
        scrollView.addSubview(view)
      }


    func removeSubviewFromScrollView(_ view: UIView)
      {
        scrollViewSubviews.remove(view)
        view.removeFromSuperview()
      }


    func updateScrollViewContentSize()
      {
        // Determine the content rect containing all approved subviews
        var maxY: CGFloat = 0
        // Iterate over all of the subviews
        for subview in scrollViewSubviews {
          // As long as the subview is not being hidden, update the maximum y coordinate
          if subview.isHidden == false {
            let candidate = subview.frame.origin.y + subview.frame.height
            maxY = max(candidate, maxY)
          }
        }

        let width = view.frame.width
        let height = maxY + 8.0

        // As long as there are changes to be made
        if width != scrollView.contentSize.width || height != scrollView.contentSize.height {
          // Animate a change to scrollView's contentSize
          UIView.animate(withDuration: 0.5, animations:
            {
              self.scrollView.contentSize = CGSize(width: width, height: height)
            })

        }
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        // Configure the root view
        view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.isOpaque = true

        // Create the scroll view
        scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.backgroundColor = UIColor.white
        scrollView.isOpaque = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Configure the layout bindings for the scroll view
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        scrollViewBottomConstraint.isActive = true

        // Create the navigation bar buttons
        endEditingButton = UIBarButtonItem(title: NSLocalizedString("END EDITING", comment: ""), style: .plain, target: self, action: #selector(self.endEditing(_:)))
        doneButton = UIBarButtonItem(title: NSLocalizedString("DONE", comment: ""), style: .plain, target: self, action: #selector(self.done(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Set the initial editing state
        setEditing(defaultEditingState, animated: true)
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Schedule a call to updateScrollViewContentSize after a slight delay
        perform(#selector(BaseViewController.updateScrollViewContentSize), with: nil, afterDelay: 0.1)

        // Register to observe notifications relating to keyboard appearance and disappearance, as well as changes to the device orientation
        NotificationCenter.default.addObserver(self, selector: #selector(BaseViewController.keyboardWillMove(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BaseViewController.keyboardWillMove(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(BaseViewController.deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register to observe notifications
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        // De-register any custom notifications
        observations.removeAll()
      }


    override func setEditing(_ editing: Bool, animated: Bool)
      {
        // Enable key-value observation for the editing property
        willChangeValue(forKey: "editing")
        super.setEditing(editing, animated: animated)
        didChangeValue(forKey: "editing")

        navigationItem.rightBarButtonItem = editing ? endEditingButton : editButtonItem
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
      {
        // Set the activeSubview to be the textField, if applicable
        if isEditing {
          activeSubview = textField
          return true
        }
        return false
      }


    func textFieldDidEndEditing(_ textField: UITextField)
      {
        if activeSubview === textField {
          activeSubview = nil
        }
      }


    // MARK: - UITextViewDelegate

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
      {
        if isEditing {
          activeSubview = textView
          return true
        }
        return false
      }


    func textViewDidEndEditing(_ textView: UITextView)
      {
        if activeSubview === textView {
          activeSubview = nil
        }
      }


    // MARK: - NSNotificationCenter

    func keyboardWillMove(_ notification: Notification)
      {
        if let subview = activeSubview {

          // Sanity check
          assert(subview.isKind(of: UITextField.self) || subview.isKind(of: UITextView.self))

          // Get the frames of the keyboard and subview
          let navFrame = navigationController!.navigationBar.frame
          let frame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
          let keyboardFrame = CGRect(x: frame.origin.x, y: frame.origin.y - (navFrame.origin.y + navFrame.height), width: frame.width, height: frame.height)
          let subviewFrame = subview.superview!.convert(subview.frame, to: view)

          // Get the overlap between the keyboard and subview
          let overlapRect = subviewFrame.intersection(keyboardFrame)

          // Get the duration of the keyboard animation
          let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double

          // If the keyboard is about to appear
          if notification.name == NSNotification.Name.UIKeyboardWillShow {

            // Disable scrolling while we're editing text
            scrollView.isScrollEnabled = false

            // If the keyboard will overlap with the active subview
            if overlapRect.height > 0 {

              // Deactivate the scroll view's bottom constraint
              scrollViewBottomConstraint.isActive = false

              // Set and activate the scroll view's height constraint
              scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: scrollView.frame.height - keyboardFrame.height)
              scrollViewHeightConstraint!.isActive = true

              // Update the scroll view's frame and content offset in an animation block
              UIView.animate(withDuration: duration, animations:
                  { () -> Void in
                    self.scrollView.frame = CGRect(x: self.scrollView.frame.origin.x, y: self.scrollView.frame.origin.y, width: self.scrollView.frame.width, height: self.scrollView.frame.height - keyboardFrame.height)
                    self.scrollView.contentOffset = CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y + subviewFrame.origin.y + subviewFrame.height - self.scrollView.frame.height)
                  })
            }
          }

          // Otherwise if the keyboard is about to disappear
          else if notification.name == NSNotification.Name.UIKeyboardWillHide {

            // Re-enable scrolling
            scrollView.isScrollEnabled = true

            // Update the scroll view's layout constraints
            scrollViewHeightConstraint?.isActive = false
            scrollViewBottomConstraint.isActive = true

            // Animate the scroll view's frame
            UIView.animate(withDuration: duration, animations:
                { () -> Void in
                  self.scrollView.frame = CGRect(x: self.scrollView.frame.origin.x, y: self.scrollView.frame.origin.y, width: self.scrollView.frame.width, height: self.view.frame.height)
                })
          }
        }
      }


    func deviceOrientationDidChange(_ notification: Notification)
      {
        // Update the scrollView's contentSize
        scrollView.contentSize = CGSize(width: view.frame.width, height: scrollView.contentSize.height)
      }


    // MARK: Actions

    func endEditing(_ sender: AnyObject?)
      {
        assert(activeSubview == nil, "unexpected state")

        // Set the editing state to false
        setEditing(false, animated: true)

        // Attempt to save the managedObjectContext
        do { try managedObjectContext.save() }
        catch let e { fatalError("failed to save: \(e)") }
      }


    func done(_ sender: AnyObject?)
      {
        // If the active subview is non-nil
        if let subview = activeSubview {

          // If the activeSubview is a textField
          if let textField = subview as? UITextField {
            // Ask it's delegate if we can return, and then have it resign as the first responder
            if textField.delegate!.textFieldShouldReturn!(textField) {
             textField.resignFirstResponder()
            }
          }
          // Otherwise, if the activeSubview is a textView
          else if let textView = subview as? UITextView {
            // Ask it's delegate if we can end editing, and then have it resign as the first responder
            if textView.delegate!.textViewShouldEndEditing!(textView) {
              textView.resignFirstResponder()
            }
          }
          // Otherwise it's some non-text view, so have it resign as first responder
          else {
            subview.resignFirstResponder()
          }
        }
      }

  }

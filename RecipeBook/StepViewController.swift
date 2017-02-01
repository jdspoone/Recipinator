/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class StepViewController: BaseViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {

    var step: Step
    var completion: (Step) -> Void


    var numberLabel: UILabel!
    var summaryTextField: UITextField!
    var detailTextView: UITextView!
    var imageView: UIImageView!


    init(step: Step, editing: Bool, context: NSManagedObjectContext, completion: (Step -> Void))
      {
        self.step = step
        self.completion = completion

        super.init(editing: editing, context: context)
      }


    func restoreState()
      {
        summaryTextField.text = step.summary
        detailTextView.text = step.detail
        imageView.image = step.image ?? UIImage(named: "defaultImage")
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        super.loadView()

        // Configure the number label
        numberLabel = UILabel(frame: CGRect.zero)
        numberLabel.text = "Step \(step.number + 1)"
        numberLabel.font = UIFont(name: "Helvetica", size: 18)
        numberLabel.textAlignment = .Center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(numberLabel)

        // Configure the summary text field
        summaryTextField = UITextField(frame: CGRect.zero)
        summaryTextField.font = UIFont(name: "Helvetica", size: 16)
        summaryTextField.placeholder = "Summary"
        summaryTextField.textAlignment = .Center
        summaryTextField.returnKeyType = .Done
        summaryTextField.translatesAutoresizingMaskIntoConstraints = false
        summaryTextField.delegate = self
        addSubviewToScrollView(summaryTextField)

        // Configure the detail text view
        detailTextView = UITextView(frame: CGRect.zero)
        detailTextView.font = UIFont(name: "Helvetica", size: 16)
        detailTextView.layer.cornerRadius = 5.0
        detailTextView.layer.borderWidth = 0.5
        detailTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
        detailTextView.translatesAutoresizingMaskIntoConstraints = false
        detailTextView.delegate = self
        addSubviewToScrollView(detailTextView)

        // Configure the image view
        imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .ScaleAspectFill
        imageView.layer.cornerRadius = 5.0
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        imageView.clipsToBounds = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(StepViewController.selectImage(_:))))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(imageView)

        // Configure the layout bindings for the number label
        numberLabel.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        numberLabel.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        numberLabel.heightAnchor.constraintEqualToConstant(30.0).active = true
        numberLabel.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the summary text field
        summaryTextField.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        summaryTextField.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        summaryTextField.heightAnchor.constraintEqualToConstant(30.0).active = true
        summaryTextField.topAnchor.constraintEqualToAnchor(numberLabel.bottomAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the detail text view
        detailTextView.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        detailTextView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        detailTextView.heightAnchor.constraintEqualToConstant(150).active = true
        detailTextView.topAnchor.constraintEqualToAnchor(summaryTextField.bottomAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the image view
        imageView.widthAnchor.constraintEqualToConstant(320.0).active = true
        imageView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        imageView.heightAnchor.constraintEqualToConstant(320.0).active = true
        imageView.topAnchor.constraintEqualToAnchor(detailTextView.bottomAnchor, constant: 8.0).active = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        restoreState()
      }


    override func viewDidLayoutSubviews()
      {
        super.viewDidLayoutSubviews()

        // Update the content size of the scroll view
        updateScrollViewContentSize()
      }


    override func viewWillAppear(animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom notifications
        observations = [
          Observation(source: self, keypaths: ["editing"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.summaryTextField.userInteractionEnabled = self.editing
                self.summaryTextField.borderStyle = self.editing ? .RoundedRect : .None
                self.detailTextView.editable = self.editing
                self.imageView.userInteractionEnabled = self.editing
              })
        ]
      }


    override func viewWillDisappear(animated: Bool)
      {
        super.viewWillDisappear(animated)

        // Execute the completion block as long as we're not presenting another view controller
        if (presentedViewController == nil) {
          completion(step)
        }
      }



    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
      {
        // Set the activeSubview to be the textField, if applicable
        if editing {
          activeSubview = textField
          return true
        }
        return false
      }


    func textFieldDidBeginEditing(textField: UITextField)
      {
        activeSubview = textField
      }


    func textFieldShouldReturn(textField: UITextField) -> Bool
      {
        textField.endEditing(true)
        return true;
      }


    func textFieldDidEndEditing(textField: UITextField)
      {
        step.summary = textField.text!

        if activeSubview === textField {
          activeSubview = nil
        }
      }


    // MARK: - UITextViewDelegate

    func textViewShouldBeginEditing(textView: UITextView) -> Bool
      {
        if editing {
          activeSubview = textView
          return true
        }
        return false
      }


    func textViewDidBeginEditing(textView: UITextView)
      {
        activeSubview = textView
      }


    func textViewDidEndEditing(textView: UITextView)
      {
        step.detail = textView.text!

        if activeSubview === textView {
          activeSubview = nil
        }
      }


    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
      {
        // The info dictionary contains multiple representations of the timage, and this uses the original
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage

        // Set imageView to display the selected image
        imageView.image = selectedImage

        // Store the selected image in the editing recipe
        step.image = selectedImage

        // Dismiss the picker
        dismissViewControllerAnimated(true, completion: nil)
      }


    func imagePickerControllerDidCancel(picker: UIImagePickerController)
      {
        // Dismiss the picker if the user cancelled
        dismissViewControllerAnimated(true, completion: nil)
      }


    // MARK: - Actions

    func selectImage(sender: UITapGestureRecognizer)
      {
        // As long as the gesture has ended
        if sender.state == .Ended {

          // Hide the keyboard
          activeSubview?.resignFirstResponder()

          // Configure a number of UIAlertActions
          var actions = [UIAlertAction]()

          // Always configure a cancel action
          actions.append(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

          // Configure a camerta button if a camera is available
          if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            actions.append(UIAlertAction(title: "Camera", style: .Default, handler:
                { (action: UIAlertAction) in
                  // Present a UIImagePickerController for the photo library
                  let imagePickerController = UIImagePickerController()
                  imagePickerController.sourceType = .Camera
                  imagePickerController.delegate = self
                  self.presentViewController(imagePickerController, animated: true, completion: nil)
                }))
          }

          // Configure a photo library button if a photo library is available
          if (UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)) {
            actions.append(UIAlertAction(title: "Photo Library", style: .Default, handler:
              { (action: UIAlertAction) in
                // Present a UIImagePickerController for the camera
                let imagePickerController = UIImagePickerController()
                imagePickerController.sourceType = .PhotoLibrary
                imagePickerController.delegate = self
                self.presentViewController(imagePickerController, animated: true, completion: nil)
              }))
          }


          // Configure a UIAlertController
          let alertController = UIAlertController(title: "Image Selection", message: "Choose the image source you'd like to use.", preferredStyle: .Alert)
          for action in actions {
            alertController.addAction(action)
          }

          // Present the UIAlertController
          presentViewController(alertController, animated: true, completion: nil)
        }
      }

  }

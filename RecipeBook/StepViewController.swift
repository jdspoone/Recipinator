/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class StepViewController: BaseViewController, UITextFieldDelegate, UITextViewDelegate
  {

    var step: Step
    var completion: (Step) -> Void


    var numberLabel: UILabel!
    var summaryTextField: UITextField!
    var detailTextView: UITextView!
    var imageViewController: ImageViewController!


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
        imageViewController.imageView.image = step.image ?? UIImage(named: "defaultImage")
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        super.loadView()

        // Configure the number label
        numberLabel = UILabel(frame: CGRect.zero)
        numberLabel.text = NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"
        numberLabel.font = UIFont(name: "Helvetica", size: 18)
        numberLabel.textAlignment = .Center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(numberLabel)

        // Configure the summary text field
        summaryTextField = UITextField(frame: CGRect.zero)
        summaryTextField.font = UIFont(name: "Helvetica", size: 16)
        summaryTextField.placeholder = NSLocalizedString("SUMMARY", comment: "")
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
        imageViewController = ImageViewController(image: step.image)
        addChildViewController(imageViewController)
        addSubviewToScrollView(imageViewController.imageView)

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
        imageViewController.imageView.widthAnchor.constraintEqualToConstant(320.0).active = true
        imageViewController.imageView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        imageViewController.imageView.heightAnchor.constraintEqualToConstant(320.0).active = true
        imageViewController.imageView.topAnchor.constraintEqualToAnchor(detailTextView.bottomAnchor, constant: 8.0).active = true
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
                self.imageViewController.setUserInteractionEnabled(self.editing)
              }),
          Observation(source: imageViewController, keypaths: ["image"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.step.image = self.imageViewController.image
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

  }

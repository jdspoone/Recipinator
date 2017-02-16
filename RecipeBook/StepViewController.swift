/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class StepViewController: BaseViewController
  {

    var step: Step
    var completion: (Step) -> Void


    var numberLabel: UILabel!
    var summaryTextField: UITextField!
    var detailTextView: UITextView!
    var imageViewController: ImageViewController!


    init(step: Step, editing: Bool, context: NSManagedObjectContext, completion: @escaping ((Step) -> Void))
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
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(numberLabel)

        // Configure the summary text field
        summaryTextField = UITextField(frame: CGRect.zero)
        summaryTextField.font = UIFont(name: "Helvetica", size: 16)
        summaryTextField.placeholder = NSLocalizedString("SUMMARY", comment: "")
        summaryTextField.textAlignment = .center
        summaryTextField.returnKeyType = .done
        summaryTextField.translatesAutoresizingMaskIntoConstraints = false
        summaryTextField.delegate = self
        addSubviewToScrollView(summaryTextField)

        // Configure the detail text view
        detailTextView = UITextView(frame: CGRect.zero)
        detailTextView.font = UIFont(name: "Helvetica", size: 16)
        detailTextView.layer.cornerRadius = 5.0
        detailTextView.layer.borderWidth = 0.5
        detailTextView.layer.borderColor = UIColor.lightGray.cgColor
        detailTextView.translatesAutoresizingMaskIntoConstraints = false
        detailTextView.delegate = self
        addSubviewToScrollView(detailTextView)

        // Configure the image view
        imageViewController = ImageViewController(image: step.image)
        addChildViewController(imageViewController)
        addSubviewToScrollView(imageViewController.imageView)

        // Configure the layout bindings for the number label
        numberLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        numberLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        numberLabel.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        numberLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the summary text field
        summaryTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        summaryTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        summaryTextField.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        summaryTextField.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the detail text view
        detailTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        detailTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        detailTextView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        detailTextView.topAnchor.constraint(equalTo: summaryTextField.bottomAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the image view
        imageViewController.imageView.widthAnchor.constraint(equalToConstant: 320.0).isActive = true
        imageViewController.imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        imageViewController.imageView.heightAnchor.constraint(equalToConstant: 320.0).isActive = true
        imageViewController.imageView.topAnchor.constraint(equalTo: detailTextView.bottomAnchor, constant: 8.0).isActive = true
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


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom notifications
        observations = [
          Observation(source: self, keypaths: ["editing"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.summaryTextField.isUserInteractionEnabled = self.isEditing
                self.summaryTextField.borderStyle = self.isEditing ? .roundedRect : .none
                self.detailTextView.isEditable = self.isEditing
                self.imageViewController.setUserInteractionEnabled(self.isEditing && self.activeSubview == nil)
              }),
          Observation(source: self, keypaths: ["activeSubview"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.imageViewController.setUserInteractionEnabled(self.isEditing && self.activeSubview == nil)
              }),
          Observation(source: imageViewController, keypaths: ["image"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.step.image = self.imageViewController.image
              })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // Execute the completion block as long as we're not presenting another view controller
        if presentedViewController == nil {
          completion(step)
        }
      }


    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField)
      {
        imageViewController.setUserInteractionEnabled(false);
      }


    func textFieldShouldReturn(_ textField: UITextField) -> Bool
      {
        textField.resignFirstResponder()
        return true;
      }


    override func textFieldDidEndEditing(_ textField: UITextField)
      {
        step.summary = textField.text!

        super.textFieldDidEndEditing(textField)
      }


    // MARK: - UITextViewDelegate

    func textViewDidBeginEditing(_ textView: UITextView)
      {
        imageViewController.setUserInteractionEnabled(false)
      }


    func textViewShouldEndEditing(_ textView: UITextView) -> Bool
      {
        textView.resignFirstResponder()
        return true
      }


    override func textViewDidEndEditing(_ textView: UITextView)
      {
        step.detail = textView.text!

        super.textViewDidEndEditing(textView)
      }

  }

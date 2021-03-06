/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class StepViewController: BaseViewController, NSFetchedResultsControllerDelegate
  {

    var step: Step
    var completion: ((Step) -> Void)?

    let imageSortingBlock: (Image, Image) -> Bool = { $0.index < $1.index }

    var summaryTextField: UITextField!
    var detailTextView: UITextView!

    var imagesFetchedResultsController: NSFetchedResultsController<Image>!
    var imagePreviewPageViewController: ImagePreviewPageViewController!


    init(step: Step, editing: Bool, context: NSManagedObjectContext, completion: ((Step) -> Void)? = nil)
      {
        self.step = step
        self.completion = completion

        super.init(editing: editing, context: context)
      }


    func restoreState()
      {
        summaryTextField.text = step.summary
        detailTextView.text = step.detail
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        super.loadView()

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

        // Configure the image preview page view controller
        imagePreviewPageViewController = ImagePreviewPageViewController(images: step.images)
        addChildViewController(imagePreviewPageViewController)
        imagePreviewPageViewController.didMove(toParentViewController: self)
        let imagePreview = imagePreviewPageViewController.view!
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(imagePreview)

        // Configure the layout bindings for the summary text field
        summaryTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        summaryTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        summaryTextField.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        summaryTextField.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the detail text view
        detailTextView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        detailTextView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        detailTextView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        detailTextView.topAnchor.constraint(equalTo: summaryTextField.bottomAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the image view
        let sideLength: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 320.0 : 640.0
        imagePreview.widthAnchor.constraint(equalToConstant: sideLength).isActive = true
        imagePreview.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        imagePreview.heightAnchor.constraint(equalToConstant: sideLength).isActive = true
        imagePreview.topAnchor.constraint(equalTo: detailTextView.bottomAnchor, constant: 8.0).isActive = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Configure the images fetch request
        let imagesFetchRequest = NSFetchRequest<Image>(entityName: "Image")
        imagesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        imagesFetchRequest.predicate = NSPredicate(format: "%K  == %@", argumentArray: ["stepUsedIn", step.objectID])

        // Configure the images fetched results controller
        imagesFetchedResultsController = NSFetchedResultsController(fetchRequest: imagesFetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        imagesFetchedResultsController.delegate = self

        // Attempt to fetch the images associated with this step
        do { try imagesFetchedResultsController.performFetch() }
        catch let e { fatalError("error: \(e)") }

        // Set the title of the navigation item
        navigationItem.title = NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"

        // Configure a gesture recognizer on the image preview view controller
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectImage(_:)))
        imagePreviewPageViewController.view!.addGestureRecognizer(gestureRecognizer)

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
              })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // If we're moving from the parentViewController, end editing and call the completion callback
        if isMovingFromParentViewController {
          endEditing(self)
          completion?(step)
        }
      }


    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
      {
        // Update the image preview view controller
        imagePreviewPageViewController.updateImages(newImages: step.images)
      }


    // MARK: - UITextFieldDelegate

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


    // MARK: - Actions

    func selectImage(_ sender: AnyObject?)
      {
        // Ensure the active subview resigns as first responder
        activeSubview?.resignFirstResponder()

        // If we're editing, or if the recipe has no images
        if isEditing || step.images.count == 0 {
          // Configure and show an ImageCollectionViewController
          let imageCollectionViewController = ImageCollectionViewController(images: step.images, imageOwner: step, editing: true, context: managedObjectContext)
          show(imageCollectionViewController, sender: self)
        }
        // Otherwise, show an ImagePageViewController
        else {
          let imagePageViewController = ImagePageViewController(images: step.images, index: imagePreviewPageViewController.currentIndex!)
          show(imagePageViewController, sender: self)
        }
      }

  }

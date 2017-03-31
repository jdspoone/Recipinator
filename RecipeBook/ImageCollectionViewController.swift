/*

  Written by Jeff Spooner

  This class presents a set of Images in a UICollectionView,
  and allows user's to add and remove images from that set.

*/

import UIKit
import CoreData


class ImageCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {

    var observations = Set<Observation>()

    var managedObjectContext: NSManagedObjectContext

    var imageOwner: BaseObject

    var images: Set<Image>
    var sortedImages: [Image]
      { return images.sorted(by: { $0.index < $1.index }) }

    let itemSpacing: CGFloat = 10

    var initialEditing: Bool

    var selectedImageIndices = Set<Int>()
      {
        // Enable key-value observation
        willSet { willChangeValue(forKey: "selectedImage") }
        didSet { didChangeValue(forKey: "selectedImage") }
      }

    var toolbar: UIToolbar!

    var addButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var endEditingButton: UIBarButtonItem!

    var reuseIdentifier: String
      { return "ImageCollectionViewCell" }


    init(images: Set<Image>, imageOwner: BaseObject, editing: Bool, context: NSManagedObjectContext)
      {
        self.images = images
        self.imageOwner = imageOwner
        self.initialEditing = editing
        self.managedObjectContext = context

        super.init(collectionViewLayout: UICollectionViewFlowLayout())
      }


    func deselectAll()
      {
        // Iterate over the set of currently selected indices and deselect them
        for index in selectedImageIndices {
          collectionView!.deselectItem(at: IndexPath(row: index, section: 0), animated: true)
        }

        // Clear the selected indices set
        selectedImageIndices.removeAll()
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        super.loadView()

        // Configure the various buttons
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImage(_:)))
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.deleteSelected(_:)))
        endEditingButton = UIBarButtonItem(title: NSLocalizedString("END EDITING", comment: ""), style: .plain, target: self, action: #selector(self.endEditing(_:)))

        // Configure the toolbar
        toolbar = UIToolbar(frame: .zero)
        toolbar.setItems([flexibleSpace, addButton, flexibleSpace, deleteButton, flexibleSpace], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Configure the layout bindings for the toolbar
        toolbar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        toolbar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        toolbar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Set the initial editing state
        setEditing(initialEditing, animated: false)

        // Configure the collection view
        collectionView!.backgroundColor = .white
        collectionView!.allowsSelection = true

        // Register our custom cell with the collection view
        collectionView!.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
      }


    override func setEditing(_ editing: Bool, animated: Bool)
      {
        willChangeValue(forKey: "isEditing")
        super.setEditing(editing, animated: animated)
        didChangeValue(forKey: "isEditing")

        // Update the navigation item
        navigationItem.rightBarButtonItem = editing ? endEditingButton : editButtonItem

        // Toggle multiple selection on the collection view
        collectionView!.allowsMultipleSelection = editing

        // Deselect any currently selected images
        deselectAll()
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom observations
        observations = [
          Observation(source: self, keypaths: ["isEditing"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.toolbar.isHidden = self.isEditing ? false : true
              }),
          Observation(source: self, keypaths: ["selectedImage"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.deleteButton.isEnabled = self.selectedImageIndices.count > 0
              })
        ]
      }


    override func viewDidAppear(_ animated: Bool)
      {
        super.viewDidAppear(animated)

        // If there are no images, automatically present the addImage alert
        if images.count == 0 {
          addImage(self)
        }
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register custom observations
        observations.removeAll()

        // If the presentedViewController is nil and we're moving from the parentViewController, end editing and call the completion callback
        if presentedViewController == nil && isMovingFromParentViewController {
          endEditing(self)
        }
      }


    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
      {
        // Get the selected image
        let index = indexPath.row

        // If we're in editing mode, add the image to the list of selected images
        if isEditing {
          selectedImageIndices.insert(index)
        }
        // Otherwise, show an ImagePageViewController
        else {
          let imagePageViewController = ImagePageViewController(images: images, index: Int(index))
          show(imagePageViewController, sender: self)
        }
      }


    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
      {
        // Remove the image from the list of selected images
        selectedImageIndices.remove(indexPath.row)
      }


    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int
      {
        return 1
      }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
      {
        return images.count
      }


    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
      {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell

        // Set the image view
        cell.imageView.image = sortedImages[indexPath.row].image

        return cell
      }


    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
      {
        // As long as we're in editing mode, deselect any currently selected images
        if isEditing {
          deselectAll()
        }

        return isEditing
      }


    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
      {
        assert(isEditing, "unexpected state")

        let sourceIndex = sourceIndexPath.row
        let destinationIndex = destinationIndexPath.row

        // Get the image we're trying to move
        let selectedImage = sortedImages[sourceIndex]

        // Determine the images that will be affected by the move
        let movedImages = images.filter { (image: Image) -> Bool in
          return sourceIndex < destinationIndex
            ? Int(image.index) <= destinationIndex && Int(image.index) > sourceIndex
            : Int(image.index) >= destinationIndex && Int(image.index) < sourceIndex
        }

        // Update the indices of the various images
        selectedImage.index = Int16(destinationIndex)
        for image in movedImages {
          image.index += sourceIndex < destinationIndex ? -1 : 1
        }
      }


    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
      {
        // Determine the width of the view
        let viewWidth = view.frame.width

        // Determine the number of items per row, assuming the device is in porttrait mode
        var itemsPerRow: CGFloat
        switch UIDevice.current.userInterfaceIdiom {
          case .phone:
            itemsPerRow = 2
          case .pad:
            itemsPerRow = 3
          default:
            fatalError("unexpected case")
        }

        // Return the calculated square size
        let width = (viewWidth - (itemSpacing * (itemsPerRow + 1))) / itemsPerRow
        return CGSize(width: width, height: width)
      }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
      {
        return UIEdgeInsets(top: itemSpacing, left: itemSpacing, bottom: itemSpacing, right: itemSpacing)
      }



    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
      {
        // Get the original version of the selected image
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage

        // Create a new Image instance, and add it to the set of recipes
        let newImage = Image(imageData: nil, index: Int16(images.count), context: managedObjectContext)
        newImage.image = selectedImage
        images.insert(newImage)

        // Reload the collection view
        collectionView?.reloadData()

        // Dismiss the picker
        dismiss(animated: true, completion: nil)
      }


    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
      {
        // Dismiss the picker
        dismiss(animated: true, completion: nil)
      }


    // MARK: - Actions

    func endEditing(_ sender: AnyObject?)
      {
        // Update the image owner's set of images
        if let recipe = imageOwner as? Recipe {
          recipe.images = images
        }
        else if let step = imageOwner as? Step {
          step.images = images
        }
        else {
          fatalError("unexepected imageOwner")
        }

        // Set the editing state to false
        setEditing(false, animated: true)

        // Attempt to save the managedObjectContext
        do { try managedObjectContext.save() }
        catch let e { fatalError("failed to save: \(e)") }
      }


    func addImage(_ sender: AnyObject?)
      {
        // Configure a number of UIAlertActions
        var actions = [UIAlertAction]()

        // Always configure a cancel action
        actions.append(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil))

        // Configure a camera button if a camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
          actions.append(UIAlertAction(title: NSLocalizedString("CAMERA", comment: ""), style: .default, handler:
              { (action: UIAlertAction) in
                // Present a UIImagePickerController for the photo library
                let imagePickerController = UIImagePickerController()
                imagePickerController.sourceType = .camera
                imagePickerController.delegate = self
                self.present(imagePickerController, animated: true, completion: nil)
              }))
        }

        // Configure a photo library button if a photo library is available
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
          actions.append(UIAlertAction(title: NSLocalizedString("PHOTO LIBRARY", comment: ""), style: .default, handler:
            { (action: UIAlertAction) in
              // Present a UIImagePickerController for the camera
              let imagePickerController = UIImagePickerController()
              imagePickerController.sourceType = .photoLibrary
              imagePickerController.delegate = self
              self.present(imagePickerController, animated: true, completion: nil)
            }))
        }

        // Configure a UIAlertController
        let alertController = UIAlertController(title: NSLocalizedString("IMAGE SELECTION", comment: ""), message: NSLocalizedString("CHOOSE THE IMAGE SOURCE YOU'D LIKE TO USE.", comment: ""), preferredStyle: .alert)
        for action in actions {
          alertController.addAction(action)
        }

        // Present the UIAlertController
        present(alertController, animated: true, completion: nil)
      }


    func deleteSelected(_ sender: AnyObject?)
      {
        // Sanity check
        assert(selectedImageIndices.count > 0, "unexpected state - no items to delete")

        // Perform a batch update on the collection view
        collectionView!.performBatchUpdates(
            {
              // Build an array of collection view index paths to remove
              let selectedIndexPaths = self.selectedImageIndices.map
                  { (index: Int) -> IndexPath in
                    return IndexPath(row: index, section: 0)
                  }

              // Build a set of the selected images, and remove them from the primary set
              let selectedImages = self.selectedImageIndices.map
                  { (index: Int) -> Image in
                    return self.sortedImages[index]
                  }
              self.images.subtract(selectedImages)

              // Delete the items at those index paths
              self.collectionView!.deleteItems(at: selectedIndexPaths)

              // Clear the set of selected image indices
              self.selectedImageIndices.removeAll()
            },
        completion:
            { (complete: Bool) in
              // Iterate over the remaining images
              for (index, image) in self.sortedImages.enumerated() {
                // Update the image index if necessary
                if image.index != Int16(index) {
                  image.index = Int16(index)
                }
              }
            })


      }


    // MARK: - ImageCollectionViewCell

    class ImageCollectionViewCell: UICollectionViewCell
      {

        var imageView: UIImageView!

        override var isSelected: Bool
          {
            didSet {
              // Indicate selection status by changing the border color of the image view
              imageView.layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.lightGray.cgColor
            }
          }


        override init(frame: CGRect)
          {
            // Call super's implementation
            super.init(frame: frame)

            // Configure the image view
            imageView = UIImageView(frame: .zero)
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 5.0
            imageView.layer.borderWidth = 1.0
            imageView.layer.borderColor = UIColor.lightGray.cgColor
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(imageView)

            // Configure the layout bindings for the image view
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
          }

        // MARK: - UIView

        required init?(coder aDecoder: NSCoder)
          {
            fatalError("init(coder:) has not been implemented")
          }

      }

  }

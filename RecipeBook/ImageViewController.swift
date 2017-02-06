/*

  Written by Jeff Spooner
  
*/

import UIKit


class ImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {

    

    var image: UIImage?
    var imageView: UIImageView!
      {
        return view as! UIImageView
      }


    init(image: UIImage?)
      {
        self.image = image

        super.init(nibName: nil, bundle: nil)
      }


    func setUserInteractionEnabled(enabled: Bool)
      {
        imageView.userInteractionEnabled = enabled
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        // Configure the image view
        view = UIImageView(frame: CGRect.zero)
        view.contentMode = .ScaleAspectFill
        view.layer.cornerRadius = 5.0
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGrayColor().CGColor
        view.clipsToBounds = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ImageViewController.selectImage(_:))))
        view.translatesAutoresizingMaskIntoConstraints = false
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        imageView.image = image
      }


    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
      {
        // The info dictionary contains multiple representations of the timage, and this uses the original
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage

        // Set imageView to display the selected image
        imageView.image = selectedImage

        // Store the selected image in the editing recipe
        image = selectedImage

        // Dismiss the picker
        dismissViewControllerAnimated(true, completion: nil)

        // Have the image view resign as first responder
        imageView.resignFirstResponder()
      }


    func imagePickerControllerDidCancel(picker: UIImagePickerController)
      {
        // Dismiss the picker if the user cancelled
        dismissViewControllerAnimated(true, completion: nil)

        // Have the image view resign as first responder
        imageView.resignFirstResponder()
      }


    // MARK: - Actions

    func selectImage(sender: UITapGestureRecognizer)
      {
        // As long as the gesture has ended
        if sender.state == .Ended {

          // Hide the keyboard, if it is being presented
          self.imageView.becomeFirstResponder()

          // Configure a number of UIAlertActions
          var actions = [UIAlertAction]()

          // Always configure a cancel action
          actions.append(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .Cancel, handler: nil))

          // Configure a camera button if a camera is available
          if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            actions.append(UIAlertAction(title: NSLocalizedString("CAMERA", comment: ""), style: .Default, handler:
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
            actions.append(UIAlertAction(title: NSLocalizedString("PHOTO LIBRARY", comment: ""), style: .Default, handler:
              { (action: UIAlertAction) in
                // Present a UIImagePickerController for the camera
                let imagePickerController = UIImagePickerController()
                imagePickerController.sourceType = .PhotoLibrary
                imagePickerController.delegate = self
                self.presentViewController(imagePickerController, animated: true, completion: nil)
              }))
          }

          // Configure a cancel button if the step has an associated image
          if let _ = image {
            actions.append(UIAlertAction(title: NSLocalizedString("DELETE IMAGE", comment: ""), style: .Default, handler:
                { (action: UIAlertAction) in
                  // Remove the associated image
                  self.image = nil
                  self.imageView.image = nil
                }))
          }

          // Configure a UIAlertController
          let alertController = UIAlertController(title: NSLocalizedString("IMAGE SELECTION", comment: ""), message: NSLocalizedString("CHOOSE THE IMAGE SOURCE YOU'D LIKE TO USE.", comment: ""), preferredStyle: .Alert)
          for action in actions {
            alertController.addAction(action)
          }

          // Present the UIAlertController
          presentViewController(alertController, animated: true, completion: nil)
        }
      }

  }

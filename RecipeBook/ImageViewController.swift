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


    func setUserInteractionEnabled(_ enabled: Bool)
      {
        imageView.isUserInteractionEnabled = enabled
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        // Configure the image view
        view = UIImageView(frame: CGRect.zero)
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 5.0
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
      {
        // The info dictionary contains multiple representations of the timage, and this uses the original
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage

        // Set imageView to display the selected image
        imageView.image = selectedImage

        // Store the selected image in the editing recipe
        image = selectedImage

        // Dismiss the picker
        dismiss(animated: true, completion: nil)

        // Have the image view resign as first responder
        imageView.resignFirstResponder()
      }


    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
      {
        // Dismiss the picker if the user cancelled
        dismiss(animated: true, completion: nil)

        // Have the image view resign as first responder
        imageView.resignFirstResponder()
      }


    // MARK: - Actions

    func selectImage(_ sender: UITapGestureRecognizer)
      {
        // As long as the gesture has ended
        if sender.state == .ended {

          // Hide the keyboard, if it is being presented
          self.imageView.becomeFirstResponder()

          // Configure a number of UIAlertActions
          var actions = [UIAlertAction]()

          // Always configure a cancel action
          actions.append(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil))

          // Configure a camera button if a camera is available
          if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
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
          if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            actions.append(UIAlertAction(title: NSLocalizedString("PHOTO LIBRARY", comment: ""), style: .default, handler:
              { (action: UIAlertAction) in
                // Present a UIImagePickerController for the camera
                let imagePickerController = UIImagePickerController()
                imagePickerController.sourceType = .photoLibrary
                imagePickerController.delegate = self
                self.present(imagePickerController, animated: true, completion: nil)
              }))
          }

          // Configure a cancel button if the step has an associated image
          if let _ = image {
            actions.append(UIAlertAction(title: NSLocalizedString("DELETE IMAGE", comment: ""), style: .default, handler:
                { (action: UIAlertAction) in
                  // Remove the associated image
                  self.image = nil
                  self.imageView.image = nil
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
      }

  }

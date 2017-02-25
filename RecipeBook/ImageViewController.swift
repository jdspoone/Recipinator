/*

  Written by Jeff Spooner

  UIViewController subclass for displaying a single image.
  Intended to be presented by a UIPageViewController.

*/

import UIKit


class ImageViewController: UIViewController
  {

    var image: Image
    var imageView: UIImageView!

    var imageViewWidthConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if imageViewWidthConstraint != nil {
            NSLayoutConstraint.deactivate([imageViewWidthConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activate([imageViewWidthConstraint])
        }
      }

    var imageViewHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if imageViewHeightConstraint != nil {
            NSLayoutConstraint.deactivate([imageViewHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activate([imageViewHeightConstraint])
        }
      }


    init(image: Image)
      {
        self.image = image

        super.init(nibName: nil, bundle: nil)
      }


    func updateImageViewLayoutConstraints()
      {
        // We're using the parent's view throughout this method instead of our own view because 
        // there are cases where this method will be called and our own view will be empty
        let parentView = parent!.view!

        // Determine if we're in portrait or landscape mode
        // NOTE: - We're doing this because when querying the current device for its orientation,
        //         it's possible that isPortrait == isLandscape
        let isPortrait = parentView.frame.width < parentView.frame.height

        let size = image.image!.size
        let aspectRatio = size.width / size.height

        // Animate
        UIView.animate(withDuration: 0.5, animations: {

          // Get the width and height of the parent view
          let viewWidth = self.parent!.view.frame.width
          let viewHeight = self.parent!.view.frame.height

          // Define variables for the width and height of the image view
          var width: CGFloat
          var height: CGFloat

          // If the device is in portrait orientation, update the height
          if isPortrait {
            width = viewWidth
            height = viewWidth / aspectRatio
          }
          // Otherwise the device is in landscape orientation, update the width
          else {
            width = viewHeight * aspectRatio
            height = viewHeight
          }

          // Update the width and height constraints of the image view
          self.imageViewWidthConstraint = self.imageView.widthAnchor.constraint(equalToConstant: width)
          self.imageViewHeightConstraint = self.imageView.heightAnchor.constraint(equalToConstant: height)
        })
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        // Configure the root view
        view = UIView(frame: .zero)

        // Configure the image view
        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // Configure the constant layout bindings for the image view
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Set the image view's image
        imageView.image = image.image
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register to observe changes to the device's orientation
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
      }


    override func viewDidAppear(_ animated: Bool)
      {
        super.viewDidAppear(animated)

        // Configure the dynamic layout bindings for the image view
        updateImageViewLayoutConstraints()
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register to observe changes to the device's orientation
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
      }


    // MARK: - NSNotificationCenter

    func deviceOrientationDidChange(_ notification: Notification)
      {
        // Re-configure the dynamic layout bindings for the image view
        updateImageViewLayoutConstraints()
      }

  }

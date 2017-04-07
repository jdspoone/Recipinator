/*

  Written by Jeff Spooner

  UIViewController subclass for displaying a single image.
  Intended to be presented by a UIPageViewController.

  Credit to Apple for code in zoomRectWithScale() - https://developer.apple.com/library/content/documentation/WindowsViews/Conceptual/UIScrollView_pg/ZoomZoom/ZoomZoom.html
*/

import UIKit


class ImageViewController: UIViewController, UIScrollViewDelegate
  {

    var image: Image

    var scrollView: UIScrollView!

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
          if imageViewWidthConstraint != nil {
            NSLayoutConstraint.activate([imageViewWidthConstraint])
          }
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
          if imageViewHeightConstraint != nil {
            NSLayoutConstraint.activate([imageViewHeightConstraint])
          }
        }
      }


    init(image: Image)
      {
        self.image = image

        super.init(nibName: nil, bundle: nil)
      }


    func getImageViewSize() -> CGSize
      {
        // We're assuming the parent view controller's view is the size of the window
        let window = UIApplication.shared.windows.first!
        let parentWidth = window.frame.width
        let parentHeight = window.frame.height

        // Determine if we're in portrait or landscape mode
        // NOTE: - We're doing this because when querying the current device for its orientation,
        //         it's possible that isPortrait == isLandscape
        let isPortrait = parentWidth < parentHeight

        // Get the aspect ratio of the image
        let imageSize = image.image!.size
        let imageAspectRatio = imageSize.width / imageSize.height

        // Get the aspect ratio of the window
        let windowAspectRatio = window.frame.width / window.frame.height

        // Define variables for the width and height of the image view
        var width: CGFloat
        var height: CGFloat

        // If the device is in portrait orientation
        if isPortrait {

          // If the aspect ratio of the image is less than that of the window
          if imageAspectRatio <= windowAspectRatio {

            // Set the height to be that of the parent and update the width
            width = parentHeight * imageAspectRatio
            height = parentHeight
          }
          // Otherwise the aspect ratio of the window is larger
          else {

            // Set the width to be that of the parent and update the height
            width = parentWidth
            height = parentWidth / imageAspectRatio
          }
        }
        // Otherwise the device is in landscape orientation, update the width
        else {

          // If the aspect ratio of the image is less than that of the window
          if imageAspectRatio <= windowAspectRatio {

            // Set the height to be that of the parent and update the width
            width = parentHeight * imageAspectRatio
            height = parentHeight
          }
          // Otherwise the aspect ratio of the window is larger
          else {

            // Set the width to be that of the parent and update the height
            width = parentWidth
            height = parentWidth / imageAspectRatio
          }
        }

        return CGSize(width: width, height: height)
      }


    func zoomRectWithScale(_ scale: CGFloat, andCenter center: CGPoint) -> CGRect
      {
        var zoomRect = CGRect()

        // Get the width and height of the zoom rect
        zoomRect.size.height = scrollView.frame.size.height / scale;
        zoomRect.size.width  = scrollView.frame.size.width  / scale;

        // Get the origin of the zoom rect
        zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);

        return zoomRect
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        // Configure the root view
        view = UIView(frame: .zero)

        // Configure the scroll view
        scrollView = UIScrollView(frame: .zero)
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        view.addSubview(scrollView)

        // Configure the image view
        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        // Configure the layout bindings for the scroll view
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Set the image view's image
        imageView.image = image.image

        // Configure a double tap gesture recognizer on the scroll view
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register to observe changes to the device's orientation
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        // Update the view's layout constraints
        view.setNeedsUpdateConstraints()
      }


    override func updateViewConstraints()
      {
        // Determine the size of the image view
        let size = self.getImageViewSize()

        // Get the zoom scale of the scroll view
        let scale = self.scrollView.zoomScale

        // Update the scroll view's content size
        scrollView.contentSize = CGSize(width: size.width * scale, height: size.height * scale)

        // Get the size of the parent view controller's view
        // Note: we're assuming the parent view controller's view is the size of the visible portion of the window
        let window = UIApplication.shared.windows.first!
        let parentWidth = window.frame.width
        let parentHeight = window.frame.height

        // Update the scroll view's content insets
        let vertical = max(parentHeight - size.height * scale, 0)
        let horizontal = max(parentWidth - size.width * scale, 0)
        scrollView.contentInset = UIEdgeInsets(top: vertical / 2, left: horizontal / 2, bottom: vertical / 2, right: horizontal / 2)

        // Update the image view's width and height constraints
        imageViewWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: size.width)
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: size.height)

        super.updateViewConstraints()
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register to observe changes to the device's orientation
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
      }


    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView?
      {
        return imageView
      }


    func scrollViewDidZoom(_ scrollView: UIScrollView)
      {
        // If the navigation bar is currently visible, hide it
        if navigationController!.navigationBar.isHidden == false {
          (parent!.parent as! ImagePageViewController).singleTap(nil)
        }

        // Get the size of the image view
        let size = getImageViewSize()

        // Get the zoom scale of the scroll view
        let scale = scrollView.zoomScale

        // Update the scroll view's content size
        scrollView.contentSize = CGSize(width: size.width * scale, height: size.height * scale)

        // Update the scroll view's content insets
        let vertical = max(scrollView.frame.height - size.height * scale, 0)
        let horizontal = max(scrollView.frame.width - size.width * scale, 0)
        scrollView.contentInset = UIEdgeInsets(top: vertical / 2, left: horizontal / 2, bottom: vertical / 2, right: horizontal / 2)
      }


    // MARK: - Actions

    func doubleTap(_ recognizer: UITapGestureRecognizer)
      {
        // Either want to zoom out
        if scrollView.zoomScale > scrollView.minimumZoomScale {
          scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        // Or we want to zoom in
        else {
          // Get the center of the tap gesture
          let center = recognizer.location(in: imageView)

          // Get the zoomed rect centered on that location
          let zoomRect = zoomRectWithScale(scrollView.maximumZoomScale, andCenter: center)

          // Zoom in on that location
          scrollView.zoom(to: zoomRect, animated: true)
        }
      }


    // MARK: - NSNotificationCenter

    func deviceOrientationDidChange(_ notification: Notification)
      {
        // Re-configure the dynamic layout bindings for the image view
        view.setNeedsUpdateConstraints()
      }

  }

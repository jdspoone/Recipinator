/*

*/

import UIKit


class ImagePreviewPageViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource
  {

    var images: Set<Image>
    var sortedImages: [Image]
      { return images.sorted(by: { $0.index < $1.index }) }

    var currentIndex: Int?
      {
        let preview = pageViewController.viewControllers!.first! as! ImagePreviewViewController
        return preview.image != nil ? Int(preview.image!.index) : nil
      }

    var pageViewController: UIPageViewController
    var pageControl: UIPageControl!

    var pageControlHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if pageControlHeightConstraint != nil {
            NSLayoutConstraint.deactivate([pageControlHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activate([pageControlHeightConstraint])
        }
      }

    var pageControlWidthConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if pageControlWidthConstraint != nil {
            NSLayoutConstraint.deactivate([pageControlWidthConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activate([pageControlWidthConstraint])
        }
      }


    init(images: Set<Image>)
      {
        self.images = images

        self.pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)

        super.init(nibName: nil, bundle: nil)

        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
      }


    func updateImages(newImages: Set<Image>)
      {
        images = newImages

        // Set the initial view controller of the page view controller
        let viewController = ImagePreviewViewController(image: sortedImages.first)
        pageViewController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)

        // Update the page control
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0

        // Get the initial size of the page control
        let size = pageControl.size(forNumberOfPages: images.count)

        // Configure the dynamic layout bindings for the page control
        pageControlHeightConstraint = pageControl.heightAnchor.constraint(equalToConstant: size.height)
        pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: size.width)
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        // Create the root view
        view = UIView(frame: .zero)

        // Configure the page view controller
        addChildViewController(pageViewController)
        let pageView = pageViewController.view!
        pageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView)

        // Configure the page control
        pageControl = UIPageControl(frame: .zero)
        pageControl.hidesForSinglePage = true
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)

        // Configure the layout bindings for the page view controller
        pageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Configure the constant layout bindings for the page control
        pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Get the initial size of the page control
        let size = pageControl.size(forNumberOfPages: images.count)

        // Configure the dynamic layout bindings for the page control
        pageControlHeightConstraint = pageControl.heightAnchor.constraint(equalToConstant: size.height)
        pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: size.width)
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Set the initial view controller of the page view controller
        let viewController = ImagePreviewViewController(image: sortedImages.first)
        pageViewController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)

        // Update the page control
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0
      }


    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
      {
        // As long as we're currently display an image preview
        if let index = (viewController as! ImagePreviewViewController).image?.index {

          // Ensure we're not displaying the very first image
          if index > 0 {
            return ImagePreviewViewController(image: sortedImages[index - 1])
          }
        }

        // Otherwise return nil
        return nil
      }


    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
      {
        // As long as we're currently displaying an image preview
        if let index = (viewController as! ImagePreviewViewController).image?.index {

          // Ensure we're not displaying the very last image
          if Int(index) < images.count - 1 {
            return ImagePreviewViewController(image: sortedImages[Int(index) + 1])
          }
        }

        // Otherwise return nil
        return nil
      }


    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
      {
        // Get the current image preview view controller
        let preview = pageViewController.viewControllers!.first! as! ImagePreviewViewController

        // Get the index of the currently display image, if applicable
        let index = preview.image != nil ? Int(preview.image!.index) : 0

        // Update the page control
        pageControl.currentPage = index
      }


    // MARK: -

    class ImagePreviewViewController: UIViewController
      {

        var image: Image?
        var imageView: UIImageView!
        var noImageLabel: UILabel!


        init(image: Image?)
          {
            self.image = image

            super.init(nibName: nil, bundle: nil)
          }
      

        // MARK: - UIViewController

        required init?(coder aDecoder: NSCoder)
          {
            fatalError("init(coder:) has not been implemented")
          }


        override func loadView()
          {
            // Create the root view
            view = UIView(frame: .zero)

            // Configure the image view
            imageView = UIImageView(frame: .zero)
            imageView.isUserInteractionEnabled = true
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 5.0
            imageView.layer.borderWidth = 0.5
            imageView.layer.borderColor = UIColor.lightGray.cgColor
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)

            // Configure the no image label
            noImageLabel = UILabel(frame: .zero)
            noImageLabel.text = NSLocalizedString("NO PHOTO SELECTED", comment: "") 
            noImageLabel.textAlignment = .center
            noImageLabel.font = UIFont(name: "Helvetica", size: 24)
            noImageLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(noImageLabel)

            // Configure the layout bindings for the image view
            imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

            // Configure the layout bindings for the no image label
            noImageLabel.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
            noImageLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            noImageLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
            noImageLabel.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
          }


        override func viewDidLoad()
          {
            super.viewDidLoad()

            // Set the image view's image
            imageView.image = image != nil ? image!.image : UIImage(named: "defaultImage")
            noImageLabel.isHidden = image != nil
          }

      }

  }

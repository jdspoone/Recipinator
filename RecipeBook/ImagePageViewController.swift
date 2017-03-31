/*

  Written by Jeff Spooner

  This class presents a set of Images via a UIPageViewController,
  and does not allow for editing. The presented view controllers 
  are expected to be ImageViewControllers.

*/


import UIKit


class ImagePageViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource
  {

    var images: Set<Image>
    var sortedImages: [Image]
      { return images.sorted(by: { $0.index < $1.index }) }

    var initialIndex: Int

    override var prefersStatusBarHidden: Bool
      {
        return navigationController!.navigationBar.isHidden
      }

    var pageViewController: UIPageViewController!
    var pageControl: UIPageControl!


    init(images: Set<Image>, index: Int)
      {
        self.images = images
        self.initialIndex = index

        super.init(nibName: nil, bundle: nil)
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.isOpaque = true

        // Configure the page view controller
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        addChildViewController(pageViewController)
        pageViewController.didMove(toParentViewController: self)
        let pageView = pageViewController.view!
        pageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView)

        // Configure the page control
        pageControl = UIPageControl(frame: .zero)
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.hidesForSinglePage = true
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)

        // Configure the layout bindings for the page view controller's view
        pageView.heightAnchor.constraint(equalToConstant: parent!.view.frame.height).isActive = true
        pageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Configure the layout bindings for the page control
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Get the size of the page control
        let size = pageControl.size(forNumberOfPages: images.count)

        // Configure the dynamic layout bindings for the page control
        pageControl.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        pageControl.widthAnchor.constraint(equalToConstant: size.width).isActive = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Configure an empty double tap gesture recognizer on the scroll view
        let doubleTap = UITapGestureRecognizer(target: self, action: nil)
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)

        // Configure a single tap gesture recognizer
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.singleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        view.addGestureRecognizer(singleTap)
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Set the page view controller's initial view controller
        let viewController = ImageViewController(image: sortedImages[initialIndex])
        pageViewController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)

        // Update the page control
        pageControl.numberOfPages = images.count
        pageControl.currentPage = initialIndex
      }


    // UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
      {
        // Iterate over the pending view controllers
        for viewController in (pendingViewControllers as! [ImageViewController]) {

          // Update the view controller's scroll view's zoom scale      
          viewController.scrollView.zoomScale = 1.0
        }
      }


    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
      {
        // Get the current image preview view controller
        let controller = pageViewController.viewControllers!.first! as! ImageViewController

        // Update the page control's current page
        pageControl.currentPage = Int(controller.image.index)
      }


    // UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
      {
        // Get the currently displayed image
        let imageViewController = viewController as! ImageViewController
        let index = Int(imageViewController.image.index)

        // As long as this isn't the first image
        if index > 0 {
          return ImageViewController(image: sortedImages[index - 1])
        }

        // Otherwise return nil
        return nil
      }


    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
      {
        // Get the currently displayed image
        let imageViewController = viewController as! ImageViewController
        let index = Int(imageViewController.image.index)

        // As long as this isn't the last image
        if index < images.count - 1 {
          return ImageViewController(image: sortedImages[index + 1])
        }

        // Otherwise return nil
        return nil
      }


    // MARK; - Actions

    func singleTap(_ recognizer: UITapGestureRecognizer? = nil)
      {
        let whiteBackground = view.backgroundColor == .white

        // Toggle visibilty of the navigation bar
        navigationController!.navigationBar.isHidden = whiteBackground

        // Toggle visibility of the status bar
        setNeedsStatusBarAppearanceUpdate()

        // Toggle visibility of the page control
        pageControl.isHidden = whiteBackground

        // Toggle the background color of view
        view.backgroundColor = whiteBackground ? .black : .white
      }
  }

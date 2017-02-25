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

    var pageViewController: UIPageViewController!


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
        // Create and configure the root view
        let window = UIApplication.shared.windows.first!
        let navigationBar = (window.rootViewController! as! UINavigationController).navigationBar

        let offset = navigationBar.frame.origin.y + navigationBar.frame.height

        let width = window.frame.width
        let height = window.frame.height - offset

        view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.backgroundColor = UIColor.white
        view.isOpaque = true

        // Configure the page view controller
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        addChildViewController(pageViewController)
        let pageView = pageViewController.view!
        pageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView)

        // Configure the layout bindings for the page view controller's view
        pageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Set the page view controller's initial view controller
        let viewController = ImageViewController(image: sortedImages[initialIndex])
        pageViewController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
      }


    // UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
      {
        // Iterate over the pending view controllers
        for viewController in (pendingViewControllers as! [ImageViewController]) {
          // Update the view controller's image view layout constraints prior to transitioning
          viewController.updateImageViewLayoutConstraints()
        }
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

  }

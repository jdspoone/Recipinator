/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class SearchViewController: UIViewController, NSFetchedResultsControllerDelegate, UIViewControllerPreviewingDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate
  {
    enum SearchCategory: Int {
      case recipe = 0
      case ingredient
      case tag
    }

    var observations = Set<Observation>()

    var searchCategory = SearchCategory.recipe

    var fetchRequest: NSFetchRequest<Recipe>!
    var fetchedResultsController: NSFetchedResultsController<Recipe>!

    var managedObjectContext: NSManagedObjectContext

    var previewingContext: UIViewControllerPreviewing?

    var searching: Bool = false

    var addButton: UIBarButtonItem!
    var searchButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!

    var toolbar: UIToolbar!
    var toolbarHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if toolbarHeightConstraint != nil {
            NSLayoutConstraint.deactivate([toolbarHeightConstraint])
          }
        }
        // Activate the new constraint if applicable
        didSet {
          if toolbarHeightConstraint != nil {
            NSLayoutConstraint.activate([toolbarHeightConstraint])
          }
        }
      }

    var searchSegmentedControl: UISegmentedControl!
    var searchSegmentedControlHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if searchSegmentedControlHeightConstraint != nil {
            NSLayoutConstraint.deactivate([searchSegmentedControlHeightConstraint])
          }
        }
        // Activate the new constraint if applicable
        didSet {
          if searchSegmentedControlHeightConstraint != nil {
            NSLayoutConstraint.activate([searchSegmentedControlHeightConstraint])
          }
        }
      }

    var searchTextField: UITextField!
    var searchTextFieldHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if searchTextFieldHeightConstraint != nil {
            NSLayoutConstraint.deactivate([searchTextFieldHeightConstraint])
          }
        }
        // Activate the new constraint if applicable
        didSet {
          if searchTextFieldHeightConstraint != nil {
            NSLayoutConstraint.activate([searchTextFieldHeightConstraint])
          }
        }
      }

    var recipeTableView: UITableView!
    var recipeTableViewTopConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if recipeTableViewTopConstraint != nil {
            NSLayoutConstraint.deactivate([recipeTableViewTopConstraint])
          }
        }
        // Activate the new constraint if applicable
        didSet {
          if recipeTableViewTopConstraint != nil {
            NSLayoutConstraint.activate([recipeTableViewTopConstraint])
          }
        }
      }


    init(context: NSManagedObjectContext)
      {
        self.managedObjectContext = context

        super.init(nibName: nil, bundle: nil)
      }


    func updateFetchedObjects()
      {
        // Attempt to fetch the various recipes
        do { try fetchedResultsController.performFetch() }
        catch let e { fatalError("error: \(e)") }

        // Update the table view
        recipeTableView.reloadData()
      }


    func setSearching(_ searching: Bool, animated: Bool)
      {
        self.searching = searching

        // Set the navigation item's title
        navigationItem.title = NSLocalizedString(searching ? "SEARCH RECIPES" : "RECIPES", comment: "")

        // Set the navigation item's buttons
        navigationItem.setRightBarButton(searching ? cancelButton : nil, animated: animated)

        // Update the various layout constraints
        searchSegmentedControlHeightConstraint = searchSegmentedControl.heightAnchor.constraint(equalToConstant: searching ? 40.0 : 0.0)
        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraint(equalToConstant: searching ? 40.0 : 0.0)
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraint(equalTo: searching ? searchTextField.bottomAnchor : view.topAnchor, constant: 0.0)
        toolbarHeightConstraint = toolbar.heightAnchor.constraint(equalToConstant: searching ? 0.0 : 40.0)

        // Toggle visibility of the search text field and the toolbar
        searchTextField.isHidden = searching ? false : true
        toolbar.isHidden = searching

        // Clear the search text field's text
        searchTextField.text = ""

        // If we're searching
        if searching {

          // Set the fetch request's predicate to reject everything
          fetchRequest.predicate = NSPredicate(value: false)

          // Make the search text field first responder
          searchTextField.becomeFirstResponder()
        }
        else {

          // Set the fetch request's predicate to nil
          fetchRequest.predicate = nil

          // Force the search text field to resign first responder status
          let _ = searchTextField.endEditing(true)
        }

        // Update the fetched results controller's list of fetched objects accordingly
        updateFetchedObjects()
      }


    func togglePreviewing()
      {
        // Either force touch is available
        if traitCollection.forceTouchCapability == .available {

          // Register for previewing recipes from the table view
          previewingContext = registerForPreviewing(with: self, sourceView: view)
        }
        // Or it's not
        else {
          // As long as we have a previewing context
          if let context = previewingContext {

            // Unregister for previewing
            unregisterForPreviewing(withContext: context)
          }
        }
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        let windowFrame = (UIApplication.shared.windows.first?.frame)!
        let navigationBarFrame = navigationController!.navigationBar.frame

        let width = windowFrame.width
        let height = windowFrame.height - (navigationBarFrame.origin.y + navigationBarFrame.height)

        // Configure the root view
        view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.backgroundColor = UIColor.white
        view.isOpaque = true

        // Configure the search segmented control
        searchSegmentedControl = UISegmentedControl(items: [NSLocalizedString("RECIPE", comment: ""), NSLocalizedString("INGREDIENT", comment: ""), NSLocalizedString("TAG", comment: "")])
        searchSegmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Helvetica", size: 16)!], for: UIControlState())
        searchSegmentedControl.selectedSegmentIndex = 0
        searchSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchSegmentedControl)

        // Configure the search text field
        searchTextField = UITextField(frame: CGRect.zero)
        searchTextField.font = UIFont(name: "Helvetica", size: 16)
        searchTextField.autocorrectionType = .no
        searchTextField.placeholder = NSLocalizedString("SEARCH RECIPES BY NAME", comment: "")
        searchTextField.textAlignment = .center
        searchTextField.returnKeyType = .done
        searchTextField.borderStyle = .roundedRect
        searchTextField.clearButtonMode = .always
        searchTextField.delegate = self
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchTextField)

        // Configure the recipe table view
        recipeTableView = UITableView(frame: CGRect.zero, style: .plain)
        recipeTableView.cellLayoutMarginsFollowReadableWidth = false
        recipeTableView.bounces = false
        recipeTableView.rowHeight = 50
        recipeTableView.dataSource = self
        recipeTableView.delegate = self
        recipeTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recipeTableView)

        // Configure the toolbar
        toolbar = UIToolbar(frame: .zero)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Configure the layout bindings for the search segmented control
        searchSegmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8.0).isActive = true
        searchSegmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8.0).isActive = true
        searchSegmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0).isActive = true
        searchSegmentedControlHeightConstraint = searchSegmentedControl.heightAnchor.constraint(equalToConstant: 0)
        searchSegmentedControlHeightConstraint.isActive = true

        // Configure the layout bindings for the search text field
        searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8.0).isActive = true
        searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8.0).isActive = true
        searchTextField.topAnchor.constraint(equalTo: searchSegmentedControl.bottomAnchor, constant: 8.0).isActive = true
        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraint(equalToConstant: 0.0)
        searchTextFieldHeightConstraint.isActive = true

        // Configure the layout bindings for the recipe table view
        recipeTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8.0).isActive = true
        recipeTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8.0).isActive = true
        recipeTableView.bottomAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraint(equalTo: view.topAnchor)
        recipeTableViewTopConstraint.isActive = true

        // Configure the layout bindings for the toolbar
        toolbar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        toolbar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        toolbarHeightConstraint = toolbar.heightAnchor.constraint(equalToConstant: 40)
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Configure our initial fetch request
        fetchRequest = NSFetchRequest<Recipe>(entityName: "Recipe")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        // Configure the fetched results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        // Attempt to fetch all recipes
        do { try fetchedResultsController.performFetch() }
        catch let e { fatalError("error: \(e)") }

        // Create the various bar button items
        addButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(SearchViewController.addRecipe(_:)))
        searchButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(SearchViewController.search(_:)))
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(SearchViewController.cancelSearch(_:)))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Configure the items of the toolbar
        toolbar.setItems([flexibleSpace, searchButton, flexibleSpace, addButton, flexibleSpace], animated: false)

        // Enable previewing if applicable
        togglePreviewing()

        // Set the initial searching state to false
        setSearching(false, animated: false)
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register observations
        observations = [
          Observation(source: searchSegmentedControl, keypaths: ["selectedSegmentIndex"], options: NSKeyValueObservingOptions(), block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in

                // Sanity check
                assert(self.searching, "unexpected state")

                // Switch on the selected segment index
                switch self.searchSegmentedControl.selectedSegmentIndex {
                  case 0:
                    self.searchCategory = .recipe
                    self.searchTextField.placeholder = NSLocalizedString("SEARCH RECIPES BY NAME", comment: "")

                  case 1:
                    self.searchCategory = .ingredient
                    self.searchTextField.placeholder = NSLocalizedString("SEARCH RECIPES BY INGREDIENT", comment: "")

                  case 2:
                    self.searchCategory = .tag
                    self.searchTextField.placeholder = NSLocalizedString("SEARCH RECIPES BY TAG", comment: "")

                  default:
                    fatalError("unexpected case")
                }

                // Clear the search text field
                self.searchTextField.text = ""

                // Set the fetch request's predicate to reject everything
                self.fetchRequest.predicate = NSPredicate(value: false)

                // Update the fetched results controller's list of fetched objects accordingly
                self.updateFetchedObjects()
            })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register observations
        observations.removeAll()
      }


    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
      {
        super.traitCollectionDidChange(previousTraitCollection)

        // Toggle previewing
        togglePreviewing()
      }


    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
      {
        // Begin the animation block
        recipeTableView.beginUpdates()
      }


    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
      {
        let recipe = anObject as! Recipe

        // Switch on the type of change
        switch type {

          case .insert:
            // Add a new row to the table
            recipeTableView.insertRows(at: [newIndexPath!], with: .fade)

          case .update:
            // Get the cell at the given index
            let cell = recipeTableView.cellForRow(at: indexPath!)!

            // Update the cell's title
            cell.textLabel!.text = recipe.name != "" ? recipe.name : NSLocalizedString("UNNAMED RECIPE", comment: "")
            cell.textLabel!.font = UIFont(name: "Helvetica", size: 18)

            // Reload the row at the given index path
            recipeTableView.reloadRows(at: [indexPath!], with: .none)

          case .delete:
            // Remove the row at the given index path
            recipeTableView.deleteRows(at: [indexPath!], with: .fade)

          case .move:
            // Reload all of the rows between the given index paths
            var rows: [IndexPath] = []
            for row in indexPath!.row ... newIndexPath!.row {
              rows.append(IndexPath(row: row, section: 0))
            }
            recipeTableView.reloadRows(at: rows, with: .fade)
        }
      }


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
      {
        // End the animation block
        recipeTableView.endUpdates()
      }


    // MARK: - UIViewControllerPreviewingDelegate

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
      {
        // Get the location of the press
        let position = recipeTableView.convert(location, from: self.view)

        // If there is a table view cell at the given location
        if let path = recipeTableView.indexPathForRow(at: position) {

          // Create a recipe view controller for the selected recipe
          let recipe = fetchedResultsController.object(at: path)
          let recipeViewController = RecipeViewController(recipe: recipe, editing: false, context: managedObjectContext)

          // Set the source rect of the previewing context to be the frame of the selected cell
          let cell = recipeTableView.cellForRow(at: path)!
          previewingContext.sourceRect = view.convert(cell.frame, from: recipeTableView)

          // Return the recipe view controller
          return recipeViewController
        }

        // Otherwise return nil
        return nil
      }


    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
      {
        // Show the given view controller
        show(viewControllerToCommit, sender: self)
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
      {
        if let text = textField.text, text != "" {
          textField.endEditing(true)
          return true
        }
        return false
      }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
      {
        // Build a Swift range from the given NSRange
        let start = textField.text!.characters.index(textField.text!.startIndex, offsetBy: range.location)
        let end = textField.text!.characters.index(textField.text!.startIndex, offsetBy: range.location + range.length)

        // Determine what the search string will be after this update
        var searchText = String(textField.text!)!
        searchText.replaceSubrange(start ..< end, with: string);

        // If the string is non-empty
        if searchText != "" {

          // Switch on the search category, updating the fetch request's predicate accordingly
          switch searchCategory {
            case .recipe:
              fetchRequest.predicate = NSPredicate(format: "%K contains[c] %@", argumentArray: ["name", searchText])

            case .ingredient:
              fetchRequest.predicate = NSPredicate(format: "ANY %K contains[c] %@", argumentArray: ["ingredientAmounts.ingredient.name", searchText])

            case .tag:
              fetchRequest.predicate = NSPredicate(format: "ANY %K contains[c] %@", argumentArray: ["tags.name", searchText])
          }
        }
        // Otherwise, set the fetch request's predicate to reject everything
        else {
          fetchRequest.predicate = NSPredicate(value: false)
        }

        // Update the fetched results controller's list of fetched objects accordingly
        updateFetchedObjects()

        // Always return true
        return true
      }


    func textFieldShouldClear(_ textField: UITextField) -> Bool
      {
          // Set the fetch request's predicate to reject everything
          fetchRequest.predicate = NSPredicate(value: false)

        // Update the fetched results controller's list of fetched objects accordingly
        updateFetchedObjects()

        return true
      }


    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        return fetchedResultsController.fetchedObjects!.count
      }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
      {
        // Ideally we want to dequeue a reusable cell here instead...
        let cell = UITableViewCell(style: .default, reuseIdentifier: "RecipeTableViewCell")

        // Get the recipe for the index path
        let recipe = fetchedResultsController.object(at: indexPath)

        // Configure the cell
        cell.textLabel!.text = recipe.name != "" ? recipe.name : NSLocalizedString("UNNAMED RECIPE", comment: "")
        cell.textLabel!.font = UIFont(name: "Helvetica", size: 18)

        // Return the cell
        return cell
      }


    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
      {
        return true
      }


    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
      {
        // Switch on the editing style
        switch editingStyle {

          case .delete:
            // Retrieve the recipe at the given index
            let recipe = fetchedResultsController.object(at: indexPath) 

            // Delete the recipe from the managed object context
            managedObjectContext.delete(recipe)

            // Attempt to save the managed object context
            do { try managedObjectContext.save() }
            catch let e { fatalError("error: \(e)") }

          default:
            fatalError("unexpected editing style: \(editingStyle)")
        }
      }


    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
      {
        // Deselect the given row
        recipeTableView.deselectRow(at: indexPath, animated: true)

        // Get the selected recipe
        let recipe = fetchedResultsController.object(at: indexPath) 

        // Create a RecipeViewController for the selected recipe, and present it
        let recipeViewController = RecipeViewController(recipe: recipe, editing: false, context: managedObjectContext)
        show(recipeViewController, sender: self)
      }


    // MARK: - Actions

    func addRecipe(_ sender: AnyObject?)
      {
        // Create a new recipe
        let recipe = Recipe(name: "", images: [], ingredientAmounts: [], steps: [], tags: [], context: managedObjectContext)

        // Configure and show a RecipeViewController for the new recipe
        let recipeViewController = RecipeViewController(recipe: recipe, editing: true, context: managedObjectContext)
        show(recipeViewController, sender: self)
      }


    func search(_ sender: AnyObject?)
      {
        setSearching(true, animated: true)
      }


    func cancelSearch(_ sender: AnyObject?)
      {
        setSearching(false, animated: true)
      }

  }

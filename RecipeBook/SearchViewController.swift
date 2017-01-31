/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class SearchViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate
  {
    enum SearchCategory: Int {
      case Recipe = 0
      case Ingredient
      case Tag
    }

    var observations = Set<Observation>()

    var searchCategory = SearchCategory.Recipe

    var recipes = [Recipe]()
    var filteredRecipes = [Recipe]()

    var managedObjectContext: NSManagedObjectContext

    var searching: Bool = false

    var addButton: UIBarButtonItem!
    var searchButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!

    var searchSegmentedControl: UISegmentedControl!
    var searchTextField: UITextField!
    var recipeTableView: UITableView!

    var searchSegmentedControlHeightConstraint: NSLayoutConstraint!
    var searchTextFieldHeightConstraint: NSLayoutConstraint!
    var recipeTableViewTopConstraint: NSLayoutConstraint!

    init(context: NSManagedObjectContext)
      {
        self.managedObjectContext = context

        super.init(nibName: nil, bundle: nil)
      }


    func setSearching(searching: Bool, animated: Bool)
      {
        self.searching = searching

        // Set the buttons of the navigationItem
        navigationItem.setLeftBarButtonItem(searching ? cancelButton : nil, animated: animated)
        navigationItem.setRightBarButtonItems(searching ? nil : [addButton, searchButton], animated: animated)

        // Deactivate the various layout constraints
        NSLayoutConstraint.deactivateConstraints([searchSegmentedControlHeightConstraint, searchTextFieldHeightConstraint, recipeTableViewTopConstraint])

        searchSegmentedControlHeightConstraint = searchSegmentedControl.heightAnchor.constraintEqualToConstant(searching ? 40.0 : 0.0)
        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraintEqualToConstant(searching ? 40.0 : 0.0)
        searchTextField.hidden = searching ? false : true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraintEqualToAnchor(searching ? searchTextField.bottomAnchor : view.topAnchor, constant: 0.0)

        // Activate the various layout constraints
        NSLayoutConstraint.activateConstraints([searchSegmentedControlHeightConstraint, searchTextFieldHeightConstraint, recipeTableViewTopConstraint])

        searchTextField.text = ""

        filteredRecipes = []

        recipeTableView.reloadData()

        searching ? searchTextField.becomeFirstResponder() : searchTextField.endEditing(true)
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        let windowFrame = (UIApplication.sharedApplication().windows.first?.frame)!
        let navigationBarFrame = navigationController!.navigationBar.frame

        let width = windowFrame.width
        let height = windowFrame.height - (navigationBarFrame.origin.y + navigationBarFrame.height)

        // Configure the root view
        view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.backgroundColor = UIColor.whiteColor()
        view.opaque = true

        // Configure the search segmented control
        searchSegmentedControl = UISegmentedControl(items: ["Recipe", "Ingredient", "Tag"])
        searchSegmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Helvetica", size: 16)!], forState: UIControlState())
        searchSegmentedControl.selectedSegmentIndex = 0
        searchSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchSegmentedControl)

        // Configure the search text field
        searchTextField = UITextField(frame: CGRect.zero)
        searchTextField.font = UIFont(name: "Helvetica", size: 16)
        searchTextField.autocorrectionType = .No
        searchTextField.placeholder = "Search recipes by name"
        searchTextField.textAlignment = .Center
        searchTextField.returnKeyType = .Done
        searchTextField.borderStyle = .RoundedRect
        searchTextField.clearButtonMode = .Always
        searchTextField.delegate = self
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchTextField)

        // Configure the recipe table view
        recipeTableView = UITableView(frame: CGRect.zero, style: .Plain)
        recipeTableView.bounces = false
        recipeTableView.rowHeight = 50
        recipeTableView.dataSource = self
        recipeTableView.delegate = self
        recipeTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recipeTableView)

        // Configure the layout bindings for the search segmented control
        searchSegmentedControl.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 8.0).active = true
        searchSegmentedControl.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -8.0).active = true
        searchSegmentedControl.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 8.0).active = true
        searchSegmentedControlHeightConstraint = searchSegmentedControl.heightAnchor.constraintEqualToConstant(0)
        searchSegmentedControlHeightConstraint.active = true

        // Configure the layout bindings for the search text field
        searchTextField.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 8.0).active = true
        searchTextField.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -8.0).active = true
        searchTextField.topAnchor.constraintEqualToAnchor(searchSegmentedControl.bottomAnchor, constant: 8.0).active = true
        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraintEqualToConstant(0.0)
        searchTextFieldHeightConstraint.active = true

        // Configure the layout bindings for the recipe table view
        recipeTableView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 8.0).active = true
        recipeTableView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -8.0).active = true
        recipeTableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        recipeTableViewTopConstraint.active = true

        // Create the required bar buttons
        addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(SearchViewController.addRecipe(_:)))
        searchButton =  UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: #selector(SearchViewController.search(_:)))
        cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(SearchViewController.cancelSearch(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Fetch all of the recipes from CoreData store
        do {
          let request = NSFetchRequest(entityName: "Recipe")
          request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

          let resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
          try resultsController.performFetch()
          if let fetchedObjects = resultsController.fetchedObjects where fetchedObjects.count > 0 {
            recipes = fetchedObjects as! [Recipe]
          }
        }
        catch let e { fatalError("error: \(e)") }

        // Configure the navigation item
        navigationItem.title = "Recipes"

        setSearching(false, animated: false)
      }


    override func viewWillAppear(animated: Bool)
      {
        // Register observations
        observations = [
          Observation(source: searchSegmentedControl, keypaths: ["selectedSegmentIndex"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                if (self.searching) {
                  // Update the search category and search text field placeholder
                  switch self.searchSegmentedControl.selectedSegmentIndex {
                    case 0:
                      self.searchCategory = .Recipe
                      self.searchTextField.placeholder = "Search recipes by name"
                    case 1:
                      self.searchCategory = .Ingredient
                      self.searchTextField.placeholder = "Search recipes by ingredient"
                    case 2:
                      self.searchCategory = .Tag
                      self.searchTextField.placeholder = "Search recipes by tag"
                    default:
                      fatalError("unexpected case")
                  }

                  // Reset the contents of search text field and the list of filtered recipes
                  self.searchTextField.text! = ""
                  self.filteredRecipes = []
                  self.recipeTableView.reloadData()
                }
              })
        ]
      }


    override func viewWillDisappear(animated: Bool)
      {
        // De-register observations
        observations.removeAll()
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool
      {
        if let text = textField.text where text != "" {
          textField.endEditing(true)
          return true
        }
        return false
      }


    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
      {
        // Build a Swift range from the given NSRange
        let start = textField.text!.startIndex.advancedBy(range.location)
        let end = textField.text!.startIndex.advancedBy(range.location + range.length)
        let swiftRange = Range<String.Index>(start ..< end)

        // Determine what the search string will be after this update
        var searchText = String(textField.text!)
        searchText.replaceRange(swiftRange, with: string)

        // If the string is non-empty
        if (searchText != "") {
          // Filter the list of recipes according to the current search category
          switch searchCategory {
            case .Recipe:
              filteredRecipes = recipes.filter({ $0.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil })

            case .Ingredient:
              filteredRecipes = recipes.filter({ $0.ingredientAmounts.filter({ $0.ingredient.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil }).count > 0 })

            case .Tag:
              filteredRecipes = recipes.filter({ $0.tags.filter({ $0.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil }).count > 0 })
          }

          // Update the recipe table view
          recipeTableView.reloadData()
        }

        // Always return true
        return true
      }


    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      { return searching ? filteredRecipes.count : recipes.count }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
      {
        // Ideally we want to dequeue a reusable cell here instead...
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "RecipeTableViewCell")

        let list = searching ? filteredRecipes : recipes
        let recipe = list[indexPath.row]

        // Configure the cell
        cell.textLabel!.text = recipe.name != "" ? recipe.name : "Unnamed recipe"
        cell.textLabel!.font = UIFont(name: "Helvetica", size: 18)

        return cell
      }


    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
      { return true }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
      {
        if editingStyle == .Delete {

          // Begin the animation block
          tableView.beginUpdates()

          // Delete the appropriate row from the tableView
          tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)

          // Remove the recipe from the list, and update the managed object context
          var recipe: Recipe
          if searching {
            recipe = filteredRecipes.removeAtIndex(indexPath.row)
            recipes.removeAtIndex(recipes.indexOf(recipe)!)
          }
          else {
            recipe = recipes.removeAtIndex(indexPath.row)
          }

          // Delete the recipe from the managedObjectContext
          managedObjectContext.deleteObject(recipe)

          // Save the managed object context
          do { try managedObjectContext.save() }
          catch let e { fatalError("error: \(e)") }

          // End the animation block
          tableView.endUpdates()
        }
        else {
          fatalError("unexpected editing style: \(editingStyle)")
        }
      }


    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
      {
        var list = searching ? filteredRecipes : recipes

        // Get the selected recipe
        let recipe = list[indexPath.row]

        // Create a RecipeViewController for the selected recipe, and present it
        let recipeViewController = RecipeViewController(recipe: recipe, editing: false, context: managedObjectContext)
            { (recipe: Recipe?) -> Void in
              list[indexPath.row] = recipe!
              tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            }
        showViewController(recipeViewController, sender: self)
      }


    // MARK: - Actions

    func addRecipe(sender: UIBarButtonItem)
      {
        // Create a RecipeViewController with no associated recipe, and present it
        let recipeViewController = RecipeViewController(recipe: Recipe(name: "", imageData: nil, ingredientAmounts: [], steps: [], tags: [], context: managedObjectContext), editing: true, context: managedObjectContext)
            { (recipe: Recipe) -> Void in
              self.recipes.append(recipe)

              do { try self.managedObjectContext.save() }
              catch let e { fatalError("error: \(e)") }

              self.recipeTableView.beginUpdates()
              self.recipeTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.recipes.count - 1, inSection: 0)], withRowAnimation: .Fade)
              self.recipeTableView.endUpdates()
            }
        showViewController(recipeViewController, sender: self)
      }


    func search(sender: UIBarButtonItem)
      { setSearching(true, animated: true) }


    func cancelSearch(sender: UIBarButtonItem)
      { setSearching(false, animated: true) }

  }

/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class SearchViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate
  {
    enum SearchCategory: Int {
      case recipe = 0
      case ingredient
      case tag
    }

    var observations = Set<Observation>()

    var searchCategory = SearchCategory.recipe

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


    func setSearching(_ searching: Bool, animated: Bool)
      {
        self.searching = searching

        // Set the buttons of the navigationItem
        navigationItem.setLeftBarButton(searching ? cancelButton : nil, animated: animated)
        navigationItem.setRightBarButtonItems(searching ? nil : [addButton, searchButton], animated: animated)

        // Deactivate the various layout constraints
        NSLayoutConstraint.deactivate([searchSegmentedControlHeightConstraint, searchTextFieldHeightConstraint, recipeTableViewTopConstraint])

        searchSegmentedControlHeightConstraint = searchSegmentedControl.heightAnchor.constraint(equalToConstant: searching ? 40.0 : 0.0)
        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraint(equalToConstant: searching ? 40.0 : 0.0)
        searchTextField.isHidden = searching ? false : true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraint(equalTo: searching ? searchTextField.bottomAnchor : view.topAnchor, constant: 0.0)

        // Activate the various layout constraints
        NSLayoutConstraint.activate([searchSegmentedControlHeightConstraint, searchTextFieldHeightConstraint, recipeTableViewTopConstraint])

        searchTextField.text = ""

        filteredRecipes = []

        recipeTableView.reloadData()

        if searching {
          searchTextField.becomeFirstResponder();
        }
        else {
          let _ = searchTextField.endEditing(true);
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
        recipeTableView.bounces = false
        recipeTableView.rowHeight = 50
        recipeTableView.dataSource = self
        recipeTableView.delegate = self
        recipeTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recipeTableView)

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
        recipeTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraint(equalTo: view.topAnchor)
        recipeTableViewTopConstraint.isActive = true

        // Create the required bar buttons
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(SearchViewController.addRecipe(_:)))
        searchButton =  UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(SearchViewController.search(_:)))
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(SearchViewController.cancelSearch(_:)))
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Fetch all of the recipes from CoreData store
        do {
          let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
          request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

          let resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
          try resultsController.performFetch()
          if let fetchedObjects = resultsController.fetchedObjects, fetchedObjects.count > 0 {
            recipes = fetchedObjects as! [Recipe]
          }
        }
        catch let e { fatalError("error: \(e)") }

        // Configure the navigation item
        navigationItem.title = NSLocalizedString("RECIPES", comment: "")

        setSearching(false, animated: false)
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register observations
        observations = [
          Observation(source: searchSegmentedControl, keypaths: ["selectedSegmentIndex"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                if self.searching {
                  // Update the search category and search text field placeholder
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

                  // Reset the contents of search text field and the list of filtered recipes
                  self.searchTextField.text! = ""
                  self.filteredRecipes = []
                  self.recipeTableView.reloadData()
                }
              })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register observations
        observations.removeAll()
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
        var searchText = String(textField.text!)
        searchText?.replaceSubrange(start ..< end, with: string);

        // If the string is non-empty
        if searchText != "" {
          // Filter the list of recipes according to the current search category
          switch searchCategory {
            case .recipe:
              filteredRecipes = recipes.filter({ $0.name.lowercased().range(of: (searchText?.lowercased())!) != nil })

            case .ingredient:
              filteredRecipes = recipes.filter({ $0.ingredientAmounts.filter({ $0.ingredient.name.lowercased().range(of: (searchText?.lowercased())!) != nil }).count > 0 })

            case .tag:
              filteredRecipes = recipes.filter({ $0.tags.filter({ $0.name.lowercased().range(of: (searchText?.lowercased())!) != nil }).count > 0 })
          }
        }
        // Otherwise, clear the filtered recipes
        else {
          filteredRecipes = []
        }

        // Update the recipe table view
        recipeTableView.reloadData()

        // Always return true
        return true
      }


    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      { return searching ? filteredRecipes.count : recipes.count }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
      {
        // Ideally we want to dequeue a reusable cell here instead...
        let cell = UITableViewCell(style: .default, reuseIdentifier: "RecipeTableViewCell")

        let list = searching ? filteredRecipes : recipes
        let recipe = list[indexPath.row]

        // Configure the cell
        cell.textLabel!.text = recipe.name != "" ? recipe.name : NSLocalizedString("UNNAMED RECIPE", comment: "")
        cell.textLabel!.font = UIFont(name: "Helvetica", size: 18)

        return cell
      }


    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
      { return true }


    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
      {
        if editingStyle == .delete {

          // Begin the animation block
          tableView.beginUpdates()

          // Delete the appropriate row from the tableView
          tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)

          // Remove the recipe from the list, and update the managed object context
          var recipe: Recipe
          if searching {
            recipe = filteredRecipes.remove(at: indexPath.row)
            recipes.remove(at: recipes.index(of: recipe)!)
          }
          else {
            recipe = recipes.remove(at: indexPath.row)
          }

          // Delete the recipe from the managedObjectContext
          managedObjectContext.delete(recipe)

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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
      {
        var list = searching ? filteredRecipes : recipes

        // Get the selected recipe
        let recipe = list[indexPath.row]

        // Create a RecipeViewController for the selected recipe, and present it
        let recipeViewController = RecipeViewController(recipe: recipe, editing: false, context: managedObjectContext)
            { (recipe: Recipe?) -> Void in
              list[indexPath.row] = recipe!
              tableView.reloadRows(at: [indexPath], with: .none)
            }
        show(recipeViewController, sender: self)
      }


    // MARK: - Actions

    func addRecipe(_ sender: UIBarButtonItem)
      {
        // Create a RecipeViewController with no associated recipe, and present it
        let recipeViewController = RecipeViewController(recipe: Recipe(name: "", imageData: nil, ingredientAmounts: [], steps: [], tags: [], context: managedObjectContext), editing: true, context: managedObjectContext)
            { (recipe: Recipe) -> Void in
              self.recipes.append(recipe)

              do { try self.managedObjectContext.save() }
              catch let e { fatalError("error: \(e)") }

              self.recipeTableView.beginUpdates()
              self.recipeTableView.insertRows(at: [IndexPath(row: self.recipes.count - 1, section: 0)], with: .fade)
              self.recipeTableView.endUpdates()
            }
        show(recipeViewController, sender: self)
      }


    func search(_ sender: UIBarButtonItem)
      { setSearching(true, animated: true) }


    func cancelSearch(_ sender: UIBarButtonItem)
      { setSearching(false, animated: true) }

  }

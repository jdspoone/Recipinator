/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class SearchViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate
  {
    var recipes = [Recipe]()
    var filteredRecipes = [Recipe]()

    var managedObjectContext: NSManagedObjectContext

    var searching: Bool = false

    var addButton: UIBarButtonItem!
    var searchButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!

    var searchTextField: UITextField!
    var recipeTableView: UITableView!

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

        navigationItem.setLeftBarButtonItem(searching ? cancelButton : nil, animated: animated)
        navigationItem.setRightBarButtonItems(searching ? nil : [addButton, searchButton], animated: animated)

        NSLayoutConstraint.deactivateConstraints([searchTextFieldHeightConstraint, recipeTableViewTopConstraint])

        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraintEqualToConstant(searching ? 30.0 : 0.0)
        searchTextField.hidden = searching ? false : true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraintEqualToAnchor(searching ? searchTextField.bottomAnchor : view.topAnchor, constant: searching ? 8.0 : 0.0)

        NSLayoutConstraint.activateConstraints([searchTextFieldHeightConstraint, recipeTableViewTopConstraint])

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

        // Configure the search text field
        searchTextField = UITextField(frame: CGRect.zero)
        searchTextField.autocorrectionType = .No
        searchTextField.placeholder = "Search recipes"
        searchTextField.textAlignment = .Center
        searchTextField.returnKeyType = .Done
        searchTextField.borderStyle = .RoundedRect
        searchTextField.delegate = self
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchTextField)

        // Configure the recipe table view
        recipeTableView = UITableView(frame: CGRect.zero, style: .Plain)
        recipeTableView.bounces = false
        recipeTableView.dataSource = self
        recipeTableView.delegate = self
        recipeTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recipeTableView)

        // Configure the layout bindings for the search text field
        searchTextField.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 8.0).active = true
        searchTextField.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 8.0).active = true
        searchTextField.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -8.0).active = true
        searchTextFieldHeightConstraint = searchTextField.heightAnchor.constraintEqualToConstant(0.0)
        searchTextFieldHeightConstraint.active = true

        // Configure the layout bindings for the recipe table view
        recipeTableView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 8.0).active = true
        recipeTableView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -8.0).active = true
        recipeTableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        recipeTableViewTopConstraint = recipeTableView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        recipeTableViewTopConstraint.active = true

        // Create the required bar buttons
        addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addRecipe:")
        searchButton =  UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "search:")
        cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelSearch:")
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
          // If there aren't any, create some default recipes
          else {
            let ingredient = Ingredient(name: "Eggs", context: managedObjectContext)
            let ingredientAmount = IngredientAmount(ingredient: ingredient, amount: "2", number: 0, context: managedObjectContext)
            let step = Step(number: 0, summary: "Do this", detail: "Do that", imageData: nil, context: managedObjectContext)
            let recipe = Recipe(name: "Recipe A", imageData: nil, ingredientAmounts: [ingredientAmount], steps: [step], tags: [], context: managedObjectContext)

            recipes = [recipe]

            try managedObjectContext.save()
          }
        }
        catch let e { fatalError("error: \(e)") }

        // Configure the navigation item
        navigationItem.title = "Recipes"

        setSearching(false, animated: false)
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


    func textFieldDidEndEditing(textField: UITextField)
      {
        if let text = textField.text where text != "" {
          filteredRecipes = recipes.filter({ $0.name.lowercaseString.rangeOfString(textField.text!.lowercaseString) != nil })
          recipeTableView.reloadData()
        }
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

        return cell
      }


    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
      { return true }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
      {
        if editingStyle == .Delete {
          var list = searching ? filteredRecipes : recipes

          // Remove the recipe from the list, and update the managed object context
          let recipe = list.removeAtIndex(indexPath.row)
          managedObjectContext.deleteObject(recipe)
          do { try managedObjectContext.save() }
          catch let e { fatalError("error: \(e)") }

          // Update the table view
          tableView.reloadData()
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

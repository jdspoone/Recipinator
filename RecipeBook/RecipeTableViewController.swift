/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class RecipeTableViewController: UITableViewController
  {

    var recipes = [Recipe]()

    var managedObjectContext: NSManagedObjectContext


    init(managedObjectContext: NSManagedObjectContext)
      {
        self.managedObjectContext = managedObjectContext

        super.init(style: .Plain)
      }

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    func addRecipe()
      {
        // Create a RecipeViewController with no associated recipe, and present it
        let recipeViewController = RecipeViewController(recipe: Recipe(name: "", imageData: nil, ingredientAmounts: [], steps: [], tags: [], context: managedObjectContext), editing: true, context: managedObjectContext)
            { (recipe: Recipe) -> Void in
              self.recipes.append(recipe)

              do { try self.managedObjectContext.save() }
              catch let e { fatalError("error: \(e)") }

              self.tableView.beginUpdates()
              self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.recipes.count - 1, inSection: 0)], withRowAnimation: .Fade)
              self.tableView.endUpdates()
            }
        showViewController(recipeViewController, sender: self)
      }


    func deleteRecipeAtIndex(index: Int)
      {
        let recipe = recipes.removeAtIndex(index)

        managedObjectContext.deleteObject(recipe)
      }


    // MARK: - UITableViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        // Configure the navigation bar by setting the view controller's navigation item
        navigationItem.title = "Recipes"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addRecipe")

        do {
          let request = NSFetchRequest(entityName: "Recipe")
          request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

          let resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
          try resultsController.performFetch()
          if let fetchedObjects = resultsController.fetchedObjects where fetchedObjects.count > 0 {
            recipes = fetchedObjects as! [Recipe]
          }
          else {
            let ingredient = Ingredient(name: "Eggs", context: managedObjectContext)
            let ingredientAmount = IngredientAmount(ingredient: ingredient, amount: "2", number: 0, context: managedObjectContext)
            let step = Step(number: 0, summary: "Do this", detail: "Do that", imageData: nil, context: managedObjectContext)
            let recipe = Recipe(name: "Recipe A", imageData: nil, ingredientAmounts: [ingredientAmount], steps: [step], tags: [], context: managedObjectContext)

            // Set up some default recipes
            recipes = [recipe]
          }

          if managedObjectContext.hasChanges {
            try managedObjectContext.save()
          }
        }
        catch let e {
          fatalError("error: \(e)")
        }
      }


    // MARK: - UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
      {
        // Get the selected recipe
        let recipe = recipes[indexPath.row]

        // Create a RecipeViewController for the selected recipe, and present it
        let recipeViewController = RecipeViewController(recipe: recipe, editing: false, context: managedObjectContext)
            { (recipe: Recipe?) -> Void in
              self.recipes[indexPath.row] = recipe!
              tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            }
        showViewController(recipeViewController, sender: self)
      }


    // MARK: - UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      { return recipes.count }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
      {
        // Ideally we want to dequeue a reusable cell here instead...
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "RecipeTableViewCell")

        let recipe = recipes[indexPath.row]

        // Configure the cell
        cell.textLabel?.text = recipe.name

        return cell
      }


    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
      { return true }


    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
      {
        if editingStyle == .Delete {
          // Remove the recipe from the list, and update the managed object context
          let recipe = recipes.removeAtIndex(indexPath.row)
          managedObjectContext.deleteObject(recipe)
          do {
            try managedObjectContext.save()
          }
          catch let e {
            fatalError("error: \(e)")
          }

          // Remove the table view row
          tableView.beginUpdates()
          tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
          tableView.endUpdates()
        }
        else {
          fatalError("unexpected editing style: \(editingStyle)")
        }
      }


  }
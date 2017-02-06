/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class RecipeViewController: BaseViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource
  {

    var recipe: Recipe
    let completion: (Recipe) -> Void

    // Use reverse ordering for the ingredientAmounts as we add them from the top of the tableView
    let ingredientAmountsSortingBlock: (IngredientAmount, IngredientAmount) -> Bool = { $0.number > $1.number }
    let stepsSortingBlock: (Step, Step) -> Bool = { return $0.number < $1.number }

    var nameTextField: UITextField!
    var imageViewController: ImageViewController!

    var ingredientAmountsTableView: UITableView!
    var ingredientsExpanded: Bool = true
      {
        // Enable key-value observation
        willSet { willChangeValueForKey("ingredientsExpanded") }
        didSet { didChangeValueForKey("ingredientsExpanded") }
      }

    var stepsTableView: UITableView!
    var stepsExpanded: Bool = true
      {
        // Enable key-value observation
        willSet { willChangeValueForKey("stepsExpanded") }
        didSet { didChangeValueForKey("stepsExpanded") }
      }

    var tagsLabel: UILabel!
    var tagsViewController: TagsViewController!
    var tagTextField: UITextField!

    var newIngredientAmount = false

    var editingIngredientIndexPath: NSIndexPath?


    var ingredientAmountsTableViewHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if ingredientAmountsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivateConstraints([ingredientAmountsTableViewHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activateConstraints([ingredientAmountsTableViewHeightConstraint])
        }
      }

    var stepsTableViewHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if stepsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivateConstraints([stepsTableViewHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activateConstraints([stepsTableViewHeightConstraint])
        }
      }

    var tagTextFieldHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet{
          if tagTextFieldHeightConstraint != nil {
            NSLayoutConstraint.deactivateConstraints([tagTextFieldHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activateConstraints([tagTextFieldHeightConstraint])
        }
      }


    var addIngredientButton: UIButton!
    var collapseIngredientsButton: UIButton!
    var addStepButton: UIButton!
    var collapseStepsButton: UIButton!


    // MARK: -

    init(recipe: Recipe, editing: Bool, context: NSManagedObjectContext, completion: (Recipe) -> Void)
      {
        self.recipe = recipe
        self.completion = completion

        super.init(editing: editing, context: context)
      }


    func restoreState()
      {
        nameTextField.text = recipe.name
        imageViewController.imageView.image = recipe.image ?? UIImage(named: "defaultImage")
      }


    func addNewIngredientAmountToRecipe()
      {
        assert(newIngredientAmount == true, "unexpected state - newIngredientAmount is false")

        // Get the tableViewCell for the new ingredientAmount
        let cell = ingredientAmountsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! IngredientAmountTableViewCell
        let name = cell.nameTextField.text!
        let amount = cell.amountTextField.text!

        // Create a new ingredient and ingredientAmount, and add it to the recipe
        let ingredient = Ingredient.withName(name, inContext: managedObjectContext)
        let ingredientAmount = IngredientAmount(ingredient: ingredient, amount: amount, number: Int16(recipe.ingredientAmounts.count), context: managedObjectContext)
        recipe.ingredientAmounts.insert(ingredientAmount)

        // Set the newIngredientAmount flag to false
        newIngredientAmount = false
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      { fatalError("init(coder:) has not been implemented") }


    override func loadView()
      {
        super.loadView()

        // Configure the name text field
        nameTextField = UITextField(frame: CGRect.zero)
        nameTextField.font = UIFont(name: "Helvetica", size: 18)
        nameTextField.placeholder = NSLocalizedString("RECIPE NAME", comment: "")
        nameTextField.textAlignment = .Center
        nameTextField.returnKeyType = .Done
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.delegate = self
        addSubviewToScrollView(nameTextField)

        // Configure the image view
        imageViewController = ImageViewController(image: recipe.image)
        addChildViewController(imageViewController)
        addSubviewToScrollView(imageViewController.imageView)

        // Configure the ingredient table view
        ingredientAmountsTableView = UITableView(frame: CGRect.zero)
        ingredientAmountsTableView.bounces = false
        ingredientAmountsTableView.rowHeight = 50
        ingredientAmountsTableView.delegate = self
        ingredientAmountsTableView.dataSource = self
        ingredientAmountsTableView.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(ingredientAmountsTableView)

        // Configure the step table view
        stepsTableView = UITableView(frame: CGRect.zero)
        stepsTableView.bounces = false
        stepsTableView.rowHeight = 50
        stepsTableView.allowsSelectionDuringEditing = true
        stepsTableView.delegate = self
        stepsTableView.dataSource = self
        stepsTableView.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(stepsTableView)

        // Configure the tags label
        tagsLabel = UILabel(frame: .zero)
        tagsLabel.text = NSLocalizedString("TAGS", comment: "")
        tagsLabel.font = UIFont(name: "Helvetica", size: 18)
        tagsLabel.textAlignment = .Center
        tagsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(tagsLabel)

        // Configure the tag view controller
        tagsViewController = TagsViewController(tags: recipe.tags, context: managedObjectContext)
        addChildViewController(tagsViewController)
        addSubviewToScrollView(tagsViewController.view)

        // Configure the tag name text field
        tagTextField = UITextField(frame: CGRect.zero)
        tagTextField.font = UIFont(name: "Helvetica", size: 18)
        tagTextField.borderStyle = .RoundedRect
        tagTextField.placeholder = NSLocalizedString("TAG NAME", comment: "")
        tagTextField.textAlignment = .Center
        tagTextField.returnKeyType = .Done
        tagTextField.clearButtonMode = .Always
        tagTextField.translatesAutoresizingMaskIntoConstraints = false
        tagTextField.delegate = self
        addSubviewToScrollView(tagTextField)

        // Configure the layout bindings for the text field
        nameTextField.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        nameTextField.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        nameTextField.heightAnchor.constraintEqualToConstant(40.0).active = true
        nameTextField.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the image view
        imageViewController.view.widthAnchor.constraintEqualToConstant(320.0).active = true
        imageViewController.view.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        imageViewController.view.heightAnchor.constraintEqualToConstant(320.0).active = true
        imageViewController.view.topAnchor.constraintEqualToAnchor(nameTextField.bottomAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the ingredient table view
        ingredientAmountsTableView.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        ingredientAmountsTableView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        ingredientAmountsTableView.topAnchor.constraintEqualToAnchor(imageViewController.view.bottomAnchor, constant: 16.0).active = true

        // Configure the layout bindings for the step table view
        stepsTableView.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        stepsTableView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        stepsTableView.topAnchor.constraintEqualToAnchor(ingredientAmountsTableView.bottomAnchor, constant: 16.0).active = true

        // Configre the layout bindings for the tags label
        tagsLabel.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        tagsLabel.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        tagsLabel.heightAnchor.constraintEqualToConstant(30.0).active = true
        tagsLabel.topAnchor.constraintEqualToAnchor(stepsTableView.bottomAnchor, constant: 16.0).active = true

        // Configure the layout bindings for the tag view
        tagsViewController.view.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        tagsViewController.view.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        tagsViewController.view.heightAnchor.constraintEqualToConstant(100.0).active = true
        tagsViewController.view.topAnchor.constraintEqualToAnchor(tagsLabel.bottomAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the tag text field
        tagTextField.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        tagTextField.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        tagTextField.topAnchor.constraintEqualToAnchor(tagsViewController.view.bottomAnchor, constant: 8.0).active = true

        addIngredientButton = roundedSquareButton(self, action: #selector(RecipeViewController.addIngredient(_:)), controlEvents: .TouchUpInside, imageName: "addImage")
        collapseIngredientsButton = roundedSquareButton(self, action: #selector(RecipeViewController.toggleIngredientsVisibility(_:)), controlEvents: .TouchUpInside, imageName: "collapseImage")
        addStepButton = roundedSquareButton(self, action: #selector(RecipeViewController.addStep(_:)), controlEvents: .TouchUpInside, imageName: "addImage")
        collapseStepsButton = roundedSquareButton(self, action: #selector(RecipeViewController.toggleStepsVisibility(_:)), controlEvents: .TouchUpInside, imageName: "collapseImage")
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        restoreState()
      }


    override func viewWillAppear(animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom notifications
        observations = [
          Observation(source: self, keypaths: ["editing"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.nameTextField.userInteractionEnabled = self.editing
                self.nameTextField.borderStyle = self.editing ? .RoundedRect : .None
                self.imageViewController.setUserInteractionEnabled(self.editing)
                self.addIngredientButton.hidden = self.editing && self.ingredientsExpanded ? false : true
                self.addStepButton.hidden = self.editing && self.stepsExpanded ? false : true
                self.tagTextField.hidden = self.editing ? false : true
                self.tagTextFieldHeightConstraint = self.tagTextField.heightAnchor.constraintEqualToConstant(self.editing ? 40 : 0)
              }),
          Observation(source: self, keypaths: ["ingredientsExpanded"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.addIngredientButton.hidden = self.editing && self.ingredientsExpanded ? false : true
              }),
          Observation(source: self, keypaths: ["stepsExpanded"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.addStepButton.hidden = self.editing && self.stepsExpanded ? false : true
              }),
          Observation(source: ingredientAmountsTableView, keypaths: ["contentSize"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.ingredientAmountsTableViewHeightConstraint = self.ingredientAmountsTableView.heightAnchor.constraintEqualToConstant(self.ingredientAmountsTableView.contentSize.height)
              }),
          Observation(source: stepsTableView, keypaths: ["contentSize"], options: .Initial, block:
              { (changes: [String : AnyObject]?) -> Void in
                self.stepsTableViewHeightConstraint = self.stepsTableView.heightAnchor.constraintEqualToConstant(self.stepsTableView.contentSize.height)
              }),
          Observation(source: tagsViewController, keypaths: ["tags"], options: NSKeyValueObservingOptions(), block:
              { (change: [String : AnyObject]?) -> Void in
                self.recipe.tags = self.tagsViewController.tags
              }),
          Observation(source: imageViewController, keypaths: ["image"], options: .Initial, block:
              { (change: [String : AnyObject]?) -> Void in
                self.recipe.image = self.imageViewController.image
              })
        ]
      }


    override func viewWillDisappear(animated: Bool)
      {
        super.viewWillDisappear(animated)

        // Execute the completion block as long as we're not presenting another view controller
        if (presentedViewController == nil) {
          completion(recipe)
        }
      }


    override func viewDidLayoutSubviews()
      {
        super.viewDidLayoutSubviews()

        // Update the content size of the scroll view
        updateScrollViewContentSize()
      }


    override func setEditing(editing: Bool, animated: Bool)
      {
        super.setEditing(editing, animated: animated)

        // Set the editing state of the various table views
        stepsTableView.setEditing(editing, animated: animated)
        tagsViewController.setEditing(editing, animated: animated)

        // Animate the presentation or hiding of the tag text field
          UIView.animateWithDuration(0.5, animations:
              { () -> Void in
                self.tagTextFieldHeightConstraint = self.tagTextField.heightAnchor.constraintEqualToConstant(self.editing ? 40 : 0)
              }, completion:
              { (complete: Bool) -> Void in
                self.updateScrollViewContentSize()
              })
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
      {
        // Set the activeSubview to be the textField, if applicable
        if editing {
          activeSubview = textField
          return true
        }
        return false
      }


    func textFieldDidBeginEditing(textField: UITextField)
      {
        // Users should not be able to interact with the imageView if they are editing a textField
        imageViewController.setUserInteractionEnabled(false);
      }


    func textFieldShouldReturn(textField: UITextField) -> Bool
      {
        switch textField {
          case nameTextField :
            // Ensure we have a non-empty string in the nameTextField before returning
            if textField.text != nil && textField.text != "" {
              textField.endEditing(true)
              return true
            }
            return false

          case tagTextField :
            textField.endEditing(true)
            return true

          default :
            fatalError("unexpected text field")
        }
      }


    func textFieldDidEndEditing(textField: UITextField)
      {
        switch textField {
          case nameTextField :
            // Update the recipe's name
            recipe.name = textField.text!

          case tagTextField :
            // As long as we've got a non-empty string, add a tag
            if textField.text != "" {
              tagsViewController.addTagWithName(textField.text!)
              textField.text = ""
            }

          default :
            fatalError("unexpected text field")
        }

        // Enable user interaction with the imageView, and set the activeSubview to nil
        imageViewController.setUserInteractionEnabled(true)
        activeSubview = nil
      }


    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
      {
        // If we're about to show the newly created ingredient cell
        if tableView === ingredientAmountsTableView && editingIngredientIndexPath == indexPath {
          dispatch_async(dispatch_get_main_queue())
              { () -> Void in
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! IngredientAmountTableViewCell
                cell.nameTextField.becomeFirstResponder()
              }
        }
      }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
      {
        switch tableView {
          case ingredientAmountsTableView :
            // Do nothing
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return

          case stepsTableView :
            // Get the list of steps, and the index of the step we're interested in
            let steps = recipe.steps.sort(stepsSortingBlock)
            let index = indexPath.row
            let step = steps[index]
            // Present a steps view controller
            let stepsViewController = StepsViewController(steps: steps, index: index, editing: editing, context: managedObjectContext, completion:
              { () in
                // Update the label of the tableView cell
                let cell = tableView.cellForRowAtIndexPath(indexPath)!
                cell.textLabel!.text = step.summary != "" ? step.summary : NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"
              })
            showViewController(stepsViewController, sender: self)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
      {
        if section == 0 {
          let view = UIView(frame: CGRect.zero)
          view.backgroundColor = UIColor.whiteColor()

          var leftButton: UIButton!
          let label = UILabel(frame: CGRect.zero)
          label.font = UIFont(name: "Helvetica", size: 18)
          var rightButton: UIButton!

          switch tableView {
            case ingredientAmountsTableView :
              leftButton = collapseIngredientsButton
              label.text = NSLocalizedString("INGREDIENTS", comment: "")
              rightButton = addIngredientButton
            case stepsTableView :
              leftButton = collapseStepsButton
              label.text = NSLocalizedString("STEPS", comment: "")
              rightButton = addStepButton
            default :
              fatalError("unexpected table view")
          }

          view.addSubview(leftButton)
          view.addSubview(rightButton)

          label.textAlignment = .Center
          label.translatesAutoresizingMaskIntoConstraints = false
          view.addSubview(label)

          leftButton.widthAnchor.constraintEqualToConstant(30.0).active = true
          leftButton.heightAnchor.constraintEqualToConstant(30.0).active = true
          leftButton.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
          leftButton.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true

          rightButton.widthAnchor.constraintEqualToConstant(30.0).active = true
          rightButton.heightAnchor.constraintEqualToConstant(30.0).active = true
          rightButton.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
          rightButton.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true

          label.leftAnchor.constraintEqualToAnchor(leftButton.rightAnchor).active = true
          label.rightAnchor.constraintEqualToAnchor(rightButton.leftAnchor).active = true
          label.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
          label.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

          return view
        }
        return nil
      }


    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
      { return section == 0 ? 30 : 0 }


    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
      {
        // Schedule a call to updateScrollViewContentSize after a slight delay
        performSelector(#selector(BaseViewController.updateScrollViewContentSize), withObject: nil, afterDelay: 0.1)
      }


    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int
      {
        switch tableView {

          case ingredientAmountsTableView :
            return newIngredientAmount ? 2 : 1

          case stepsTableView :
            return 1

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        switch tableView {

          case ingredientAmountsTableView :

            // Switch on the section
            switch section {

              case 0:
                // Section 0 should contain 1 row if we're adding a new ingredientAmount, and a row for each ingredientAmount otherwise
                return newIngredientAmount ? 1 : recipe.ingredientAmounts.count

              case 1:
                // Sanity check
                assert(newIngredientAmount, "unexpected state")

                // If it exists, section 1 should contain a row for each ingredientAmount
                return recipe.ingredientAmounts.count

              default:
                fatalError("unexpected section")
            }

          case stepsTableView :
            return recipe.steps.count

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
      {
        // Switch on the tableView
        switch tableView {

          case ingredientAmountsTableView :

            // Switch on the section
            switch indexPath.section {

              case 0:
                // If we're creating a new ingredientAmount, return an empty ingredientAmountTableViewCell for it
                if newIngredientAmount {
                  return IngredientAmountTableViewCell(parentTableView: tableView)
                }
                // Otherwise return an ingredientAmountTableViewCell for the appropriate ingredientAmount
                else {
                  let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
                  return IngredientAmountTableViewCell(parentTableView: tableView, ingredientAmount: ingredientAmount)
                }

              case 1:
                // Sanity check
                assert(newIngredientAmount, "unexpected state")

                // Return an ingredientAmountTableViewCell for the appropriate ingredientAmount
                let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
                return IngredientAmountTableViewCell(parentTableView: tableView, ingredientAmount: ingredientAmount)

              default:
                fatalError("unexpected section")
            }

          case stepsTableView :
            let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
            let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
            cell.textLabel!.text = step.summary != "" ? step.summary : NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"
            cell.textLabel!.font = UIFont(name: "Helvetica", size: 16)
            cell.showsReorderControl = true
            return cell

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
      { return editing }


    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
      {
        // We only expect to be modifying the table views when we're in editing mode
        assert(editing == true, "unexpected state")

        // Begin the animation block
        tableView.beginUpdates()

        // Remove the appropriate row from the tableView
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

        switch tableView {
          case ingredientAmountsTableView :
            // Delete the selected ingredientAmount
            if editingStyle == .Delete {
              let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
              recipe.ingredientAmounts.remove(ingredientAmount)
              managedObjectContext.deleteObject(ingredientAmount)
            }
          case stepsTableView :
            // Delete the selected step
            if editingStyle == .Delete {
              let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
              recipe.steps.remove(step)
              managedObjectContext.deleteObject(step)
            }
          default :
            fatalError("unexpected table view")
        }

        // End the animation block
        tableView.endUpdates()
      }


    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
      { return editing }


    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
      {
        switch tableView {
          case ingredientAmountsTableView :
            fatalError("ingredient amount reordering has not been implemented")

          case stepsTableView :
            // Get handles on the steps and step numbers we're going to be working with
            let sourceStep = recipe.steps.sort(stepsSortingBlock)[sourceIndexPath.row]
            let sourceNumber = sourceStep.number

            let destinationStep = recipe.steps.sort(stepsSortingBlock)[destinationIndexPath.row]
            let destinationNumber = destinationStep.number

            // Determine which steps will be affected by the reordering
            let movedSteps = recipe.steps.filter({ return sourceNumber < destinationNumber ? $0.number <= destinationNumber && $0.number > sourceNumber : $0.number >= destinationNumber && $0.number < sourceNumber })

            // Update the order of the steps
            sourceStep.number = destinationStep.number
            for step in movedSteps {
              step.number += sourceNumber < destinationNumber ? -1 : 1
            }

          default :
            fatalError("unexpected table view")
        }
      }


    // MARK: - Actions

    override func save(sender: AnyObject?)
      {
        // If there is new (and thus unsaved) ingredientAmount, add it to the recipe
        if (newIngredientAmount == true) {
          addNewIngredientAmountToRecipe()
        }

        super.save(sender)

        do { try managedObjectContext.save() }
        catch { fatalError("failed to save") }
      }


    override func done(sender: AnyObject?)
      {
        // If the active subview is a text field
        if activeSubview!.isKindOfClass(UITextField) {
          // Treat the done button like the return button
          let textField = activeSubview as! UITextField
          textField.delegate!.textFieldShouldReturn!(textField)
        }
        // Or some non-text view
        else {
          super.done(sender)
        }
      }


    func addIngredient(sender: AnyObject)
      {
        assert(ingredientsExpanded, "Unexpected state - ingredients table view is collapsed")

        // If there already is a new ingredientAmount, we need to add it to the recipe before proceeding
        if (newIngredientAmount == true) {
          let cell = ingredientAmountsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! IngredientAmountTableViewCell

          // If the new ingredientAmount has a valid name, add it to the recipe
          if let name = cell.nameTextField.text where name != "" {
            addNewIngredientAmountToRecipe()
          }
          // Otherwise, return
          else {
            return
          }
        }

        // Flip the newIngredientAmount flag and set the editingIngredientIndexPath approriately
        newIngredientAmount = true;
        editingIngredientIndexPath = NSIndexPath(forRow: 0, inSection: 0)

        // Reload the ingredientAmountsTableView's data
        ingredientAmountsTableView.reloadData()
      }


    func addStep(sender: AnyObject)
      {
        assert(stepsExpanded, "Unexpected state - steps table view is collapsed")

        let step = Step(number: Int16(recipe.steps.count), summary: "", detail: "", imageData: nil, context: managedObjectContext, insert: false)
        let stepViewController = StepViewController(step: step, editing: true, context: managedObjectContext)
            { (step: Step) -> Void in

              // Begin the animation block
              self.stepsTableView.beginUpdates()

              // Insert the returned step into the managed object context, and update the recipe
              self.managedObjectContext.insertObject(step)
              self.recipe.steps.insert(step)

              do { try self.managedObjectContext.save() }
              catch { fatalError("failed to save") }

              // Insert a new row into the table view
              let indexPath = NSIndexPath(forRow: Int(step.number), inSection: 0)
              self.stepsTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

              // End the animation block
              self.stepsTableView.endUpdates()
            }
        showViewController(stepViewController, sender: self)
      }


    func toggleIngredientsVisibility(sender: AnyObject)
      {
        if ingredientAmountsTableView.frame.height == ingredientAmountsTableView.contentSize.height {
          collapseIngredients()
        }
        else {
          expandIngredients()
        }
      }


    func expandIngredients()
      {
        let ingredients = self.ingredientAmountsTableView

        UIView.animateWithDuration(0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseIngredientsButton.imageView!.transform = CGAffineTransformMakeRotation(0)
              // Expand the tableview
              self.ingredientAmountsTableViewHeightConstraint = ingredients.heightAnchor.constraintEqualToConstant(ingredients.contentSize.height)
              ingredients.frame = CGRect(x: ingredients.frame.origin.x, y: ingredients.frame.origin.y, width: ingredients.frame.width, height: ingredients.contentSize.height)
              ingredients.scrollEnabled = true
           },
          completion:
            { (complete: Bool) -> Void in
              // Adjust the content size of the scroll view
              self.ingredientsExpanded = true
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height + (ingredients.contentSize.height - self.collapseIngredientsButton.frame.height))
            })
      }


    func collapseIngredients()
      {
        let ingredients = self.ingredientAmountsTableView

        UIView.animateWithDuration(0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseIngredientsButton.imageView!.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
              // Collapse the tableview
              ingredients.frame = CGRect(x: ingredients.frame.origin.x, y: ingredients.frame.origin.y, width: ingredients.frame.width, height: self.collapseIngredientsButton.frame.height)
              ingredients.scrollEnabled = false
           },
          completion:
            { (compete: Bool) -> Void in
              // Update the height contraint of the ingredient amounts table view, and adjust the content size of the scroll view
              self.ingredientsExpanded = false
              self.ingredientAmountsTableViewHeightConstraint = ingredients.heightAnchor.constraintEqualToConstant(self.collapseIngredientsButton.frame.height)
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height - (ingredients.contentSize.height - self.collapseIngredientsButton.frame.height))
            })
      }


    func toggleStepsVisibility(sender: AnyObject)
      {
        if stepsTableView.frame.height == stepsTableView.contentSize.height {
          collapseSteps()
        }
        else {
          expandSteps()
        }
      }


    func expandSteps()
      {
        let tableView = self.stepsTableView

        UIView.animateWithDuration(0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseStepsButton.imageView!.transform = CGAffineTransformMakeRotation(0)
              // Expand the tableview
              self.stepsTableViewHeightConstraint = tableView.heightAnchor.constraintEqualToConstant(tableView.contentSize.height)
              tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.width, height: tableView.contentSize.height)
              tableView.scrollEnabled = true
           }, completion:
            { (complete: Bool) -> Void in
              // Adjust the content size of the scroll view
              self.stepsExpanded = true
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height + (tableView.contentSize.height - self.collapseStepsButton.frame.height))
            })
      }


    func collapseSteps()
      {

        let tableView = self.stepsTableView

        UIView.animateWithDuration(0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseStepsButton.imageView!.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
              // Collapse the table view
              tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.width, height: self.collapseStepsButton.frame.height)
              tableView.scrollEnabled = false
           },
          completion:
            { (compete: Bool) -> Void in
              // Update the height contraint of the steps table view, and adjust the content size of the scroll view
              self.stepsExpanded = false
              self.stepsTableViewHeightConstraint = tableView.heightAnchor.constraintEqualToConstant(self.collapseStepsButton.frame.height)
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height - (tableView.contentSize.height - self.collapseStepsButton.frame.height))
            })
      }

  }

/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class RecipeViewController: ScrollingViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource
  {

    var observations: Set<Observation>

    var recipe: Recipe
    let completion: (Recipe) -> Void

    var managedObjectContext: NSManagedObjectContext

    let ingredientAmountsSortingBlock: (IngredientAmount, IngredientAmount) -> Bool = { $0.number < $1.number }
    let stepsSortingBlock: (Step, Step) -> Bool = { return $0.number < $1.number }

    var nameTextField: UITextField!
    var imageView: UIImageView!
    var ingredientAmountsTableView: UITableView!
    var stepsTableView: UITableView!
    var tagsLabel: UILabel!
    var tagsViewController: TagsViewController!
    var tagTextField: UITextField!

    var newIngredientAmount = false

    var editingIngredientIndexPath: NSIndexPath?


    var ingredientAmountsTableViewHeightConstraint: NSLayoutConstraint!
      {
        willSet {
          if ingredientAmountsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivateConstraints([ingredientAmountsTableViewHeightConstraint])
          }
        }
        didSet {
          NSLayoutConstraint.activateConstraints([ingredientAmountsTableViewHeightConstraint])
        }
      }

    var stepsTableViewHeightConstraint: NSLayoutConstraint!
      {
        willSet {
          if stepsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivateConstraints([stepsTableViewHeightConstraint])
          }
        }
        didSet {
          NSLayoutConstraint.activateConstraints([stepsTableViewHeightConstraint])
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

        self.managedObjectContext = context

        self.observations = Set<Observation>()

        super.init(editing: editing)
      }


    func restoreState()
      {
        nameTextField.text = recipe.name
        imageView.image = recipe.image ?? UIImage(named: "defaultImage")
      }


    func updateLayoutConstraints()
      {
        // Deactivate
        if ingredientAmountsTableViewHeightConstraint != nil && stepsTableViewHeightConstraint != nil {
          NSLayoutConstraint.deactivateConstraints([ingredientAmountsTableViewHeightConstraint, stepsTableViewHeightConstraint])
        }

        // Set
        ingredientAmountsTableViewHeightConstraint = ingredientAmountsTableView.heightAnchor.constraintEqualToConstant(ingredientAmountsTableView.contentSize.height)
        stepsTableViewHeightConstraint = stepsTableView.heightAnchor.constraintEqualToConstant(stepsTableView.contentSize.height)

        // Activate
        NSLayoutConstraint.activateConstraints([ingredientAmountsTableViewHeightConstraint, stepsTableViewHeightConstraint])

        // Set the content size of the scroll view
        let finalSubview = editing ? tagTextField : tagsViewController.view
        scrollView.contentSize = CGSize(width: view.frame.width, height: finalSubview.frame.origin.y + finalSubview.frame.height + 8.0)
      }


    func addNewIngredientAmountToRecipe()
      {
        assert(newIngredientAmount == true, "unexpected state - newIngredientAmount is false")

        // Get the tableViewCell for the new ingredientAmount
        let cell = ingredientAmountsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! NewIngredientAmountTableViewCell
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
        nameTextField.placeholder = "Recipe name"
        nameTextField.textAlignment = .Center
        nameTextField.returnKeyType = .Done
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.delegate = self
        scrollView.addSubview(nameTextField)

        // Configure the image view
        imageView = UIImageView(frame: CGRect.zero)
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(RecipeViewController.selectImage(_:))))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        // Configure the ingredient table view
        ingredientAmountsTableView = UITableView(frame: CGRect.zero)
        ingredientAmountsTableView.bounces = false
        ingredientAmountsTableView.delegate = self
        ingredientAmountsTableView.dataSource = self
        ingredientAmountsTableView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(ingredientAmountsTableView)

        // Configure the step table view
        stepsTableView = UITableView(frame: CGRect.zero)
        stepsTableView.bounces = false
        stepsTableView.allowsSelectionDuringEditing = true
        stepsTableView.delegate = self
        stepsTableView.dataSource = self
        stepsTableView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stepsTableView)

        // Configure the tags label
        tagsLabel = UILabel(frame: .zero)
        tagsLabel.text = "Tags"
        tagsLabel.textAlignment = .Center
        tagsLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tagsLabel)

        // Configure the tag view controller
        tagsViewController = TagsViewController(tags: recipe.tags, context: managedObjectContext)
        scrollView.addSubview(tagsViewController.view)

        // Configure the tag name text field
        tagTextField = UITextField(frame: CGRect.zero)
        tagTextField.borderStyle = .RoundedRect
        tagTextField.placeholder = "Tag name"
        tagTextField.textAlignment = .Center
        tagTextField.returnKeyType = .Done
        tagTextField.clearButtonMode = .Always
        tagTextField.translatesAutoresizingMaskIntoConstraints = false
        tagTextField.delegate = self
        scrollView.addSubview(tagTextField)

        // Configure the layout bindings for the text field
        nameTextField.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        nameTextField.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        nameTextField.heightAnchor.constraintEqualToConstant(30.0).active = true
        nameTextField.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the image view
        imageView.widthAnchor.constraintEqualToConstant(320.0).active = true
        imageView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        imageView.heightAnchor.constraintEqualToConstant(320.0).active = true
        imageView.topAnchor.constraintEqualToAnchor(nameTextField.bottomAnchor, constant: 8.0).active = true

        // Configure the layout bindings for the ingredient table view
        ingredientAmountsTableView.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        ingredientAmountsTableView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        ingredientAmountsTableView.topAnchor.constraintEqualToAnchor(imageView.bottomAnchor, constant: 16.0).active = true

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
        tagTextField.heightAnchor.constraintEqualToConstant(30.0).active = true
        tagTextField.topAnchor.constraintEqualToAnchor(tagsViewController.view.bottomAnchor, constant: 8.0).active = true

        addIngredientButton = roundedSquareButton(self, action: #selector(RecipeViewController.addIngredient(_:)), controlEvents: .TouchUpInside, imageName: "addImage")
        collapseIngredientsButton = roundedSquareButton(self, action: #selector(RecipeViewController.collapseIngredients(_:)), controlEvents: .TouchUpInside, imageName: "collapseImage")
        addStepButton = roundedSquareButton(self, action: #selector(RecipeViewController.addStep(_:)), controlEvents: .TouchUpInside, imageName: "addImage")
        collapseStepsButton = roundedSquareButton(self, action: #selector(RecipeViewController.collapseSteps(_:)), controlEvents: .TouchUpInside, imageName: "collapseImage")
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
                self.addIngredientButton.hidden = self.editing ? false : true
                self.addStepButton.hidden = self.editing ? false : true
                self.tagTextField.hidden = self.editing ? false : true
              }),
          Observation(source: tagsViewController, keypaths: ["tags"], options: NSKeyValueObservingOptions(), block:
              { (change: [String : AnyObject]?) -> Void in
                self.recipe.tags = self.tagsViewController.tags
              })
        ]
      }


    override func viewWillDisappear(animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register custom notifications
        observations.removeAll()

        // Call our completion block
        completion(recipe)
      }


    override func viewDidLayoutSubviews()
      {
        super.viewDidLayoutSubviews()

        updateLayoutConstraints()
      }


    override func setEditing(editing: Bool, animated: Bool)
      {
        super.setEditing(editing, animated: animated)

        nameTextField.userInteractionEnabled = editing
        nameTextField.borderStyle = editing ? .RoundedRect : .None
        imageView.userInteractionEnabled = editing

        stepsTableView.setEditing(editing, animated: animated)
        tagsViewController.setEditing(editing, animated: animated)
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
      {
        if editing {
          activeSubview = textField
          return true
        }
        return false
      }


    func textFieldDidBeginEditing(textField: UITextField)
      {
        imageView.userInteractionEnabled = false;
      }


    func textFieldShouldReturn(textField: UITextField) -> Bool
      {
        switch textField {
          case nameTextField :
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
            recipe.name = textField.text!

          case tagTextField :
            if textField.text != "" {
              tagsViewController.addTagWithName(textField.text!)
              textField.text = ""
            }

          default :
            fatalError("unexpected text field")
        }

        imageView.userInteractionEnabled = true

        activeSubview = nil
      }



    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
      {
        // The info dictionary contains multiple representations of the timage, and this uses the original
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage

        // Set imageView to display the selected image
        imageView.image = selectedImage

        // Store the selected image in the editing recipe
        recipe.image = selectedImage

        // Dismiss the picker
        dismissViewControllerAnimated(true, completion: nil)
      }


    func imagePickerControllerDidCancel(picker: UIImagePickerController)
      {
        // Dismiss the picker if the user cancelled
        dismissViewControllerAnimated(true, completion: nil)
      }


    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
      {
        // If we're about to show the newly created ingredient cell
        if tableView === ingredientAmountsTableView && editingIngredientIndexPath == indexPath {
          dispatch_async(dispatch_get_main_queue())
              { () -> Void in
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! NewIngredientAmountTableViewCell
                cell.nameTextField.becomeFirstResponder()
              }
        }
      }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
      {
        switch tableView {
          case ingredientAmountsTableView :
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return

          case stepsTableView :
            let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
            let stepViewController = StepViewController(step: step, editing: editing, context: managedObjectContext)
                { (step: Step) -> Void in
                  if self.managedObjectContext.hasChanges {
                    do { try self.managedObjectContext.save() }
                    catch { fatalError("failed to save") }
                  }

                  self.stepsTableView.reloadData()
                }
            showViewController(stepViewController, sender: self)
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
          var rightButton: UIButton!

          switch tableView {
            case ingredientAmountsTableView :
              leftButton = collapseIngredientsButton
              label.text = "Ingredients"
              rightButton = addIngredientButton
            case stepsTableView :
              leftButton = collapseStepsButton
              label.text = "Steps"
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


    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int
      {
        switch tableView {
          case ingredientAmountsTableView :
            return newIngredientAmount == false ? 1 : 2
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
            return section == 0 ? recipe.ingredientAmounts.count : 1

          case stepsTableView :
            return recipe.steps.count

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
      {
        switch tableView {
          case ingredientAmountsTableView :
            // Either we're working with pre-existing ingredient amounts
            if indexPath.section == 0 {
              let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
              return IngredientAmountTableViewCell(ingredientAmount: ingredientAmount, tableView: tableView)
            }
            // Or we're creating a new ingredient amount
            else {
              return NewIngredientAmountTableViewCell(tableView: tableView)
            }

          case stepsTableView :
            let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
            let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
            cell.textLabel?.text = step.summary != "" ? step.summary : "Step \(step.number + 1)"
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

        switch tableView {
          case ingredientAmountsTableView :
            if editingStyle == .Delete {
              let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
              recipe.ingredientAmounts.remove(ingredientAmount)
              managedObjectContext.deleteObject(ingredientAmount)

              tableView.reloadData()
            }
          case stepsTableView :
            if editingStyle == .Delete {
              let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
              recipe.steps.remove(step)
              managedObjectContext.deleteObject(step)

              tableView.reloadData()
            }
          default :
            fatalError("unexpected table view")
        }

        view.layoutSubviews()
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

    override func save(sender: UIBarButtonItem)
      {
        // If there is new (and thus unsaved) ingredientAmount, add it to the recipe
        if (newIngredientAmount == true) {
          addNewIngredientAmountToRecipe()
        }

        super.save(sender)

        do { try managedObjectContext.save() }
        catch { fatalError("failed to save") }
      }


    override func done(sender: UIBarButtonItem)
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


    func selectImage(sender: UITapGestureRecognizer)
      {
        if sender.state == .Ended {

          // Hide the keyboard
          activeSubview?.resignFirstResponder()

          // UIImagePickerController is a view controller that lets a user pick media from their photo library
          let imagePickerController = UIImagePickerController()

          // Only allow photos to be picked, not taken
          imagePickerController.sourceType = .PhotoLibrary

          // Make sure ViewController is notified when the user picks an image
          imagePickerController.delegate = self

          presentViewController(imagePickerController, animated: true, completion: nil)
        }
      }


    func addIngredient(sender: AnyObject)
      {
        // If there already is a new ingredientAmount, we need to add it to the recipe before proceeding
        if (newIngredientAmount == true) {
          let cell = ingredientAmountsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! NewIngredientAmountTableViewCell

          // If the new ingredientAmount has a valid name, add it to the recipe
          if let name = cell.nameTextField.text where name != "" {
            addNewIngredientAmountToRecipe()
          }
          // Otherwise, return
          else {
            return
          }
        }

        // Set the newIngredientAmount flag and the editingIngredientIndexPath
        newIngredientAmount = true;
        editingIngredientIndexPath = NSIndexPath(forRow: 0, inSection: 1)

        // Reload the ingredientAmountsTableView and layout subviews
        ingredientAmountsTableView.reloadData()
        view.layoutSubviews()
      }


    func addStep(sender: AnyObject)
      {
        let step = Step(number: Int16(recipe.steps.count), summary: "", detail: "", imageData: nil, context: managedObjectContext, insert: false)
        let stepViewController = StepViewController(step: step, editing: true, context: managedObjectContext)
            { (step: Step) -> Void in
              // Insert the returned step into the managed object context, and update the recipe
              self.managedObjectContext.insertObject(step)
              self.recipe.steps.insert(step)

              do { try self.managedObjectContext.save() }
              catch { fatalError("failed to save") }

              self.stepsTableView.reloadData()

              self.view.layoutSubviews()
            }
        showViewController(stepViewController, sender: self)
      }


    func collapseIngredients(sender: AnyObject)
      {
        let ingredients = self.ingredientAmountsTableView

        // Either we're collapsing the table view
        if ingredientAmountsTableView.frame.height == ingredientAmountsTableView.contentSize.height {
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
                self.ingredientAmountsTableViewHeightConstraint = ingredients.heightAnchor.constraintEqualToConstant(self.collapseIngredientsButton.frame.height)
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height - (ingredients.contentSize.height - self.collapseIngredientsButton.frame.height))

              })
        }
        // Or we're expanding it
        else {
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
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height + (ingredients.contentSize.height - self.collapseIngredientsButton.frame.height))
              })
        }
      }


    func collapseSteps(sender: AnyObject)
      {
        let tableView = self.stepsTableView

        // Either we're collapsing the table view
        if tableView.frame.height == tableView.contentSize.height {
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
                self.stepsTableViewHeightConstraint = tableView.heightAnchor.constraintEqualToConstant(self.collapseStepsButton.frame.height)
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height - (tableView.contentSize.height - self.collapseStepsButton.frame.height))
              })
        }
        // Or we're expanding it
        else {
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
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height + (tableView.contentSize.height - self.collapseStepsButton.frame.height))
              })
        }
      }

  }

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
    var ingredientsTableView: UITableView!
    var stepsTableView: UITableView!
    var tagsViewController: TagsViewController!
    var tagTextField: UITextField!

    var newIngredientAmount: IngredientAmount?

    var editingIngredientIndexPath: NSIndexPath?


    var ingredientsTableViewHeightConstraint: NSLayoutConstraint!
      {
        willSet {
          if ingredientsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivateConstraints([ingredientsTableViewHeightConstraint])
          }
        }
        didSet {
          NSLayoutConstraint.activateConstraints([ingredientsTableViewHeightConstraint])
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
        if ingredientsTableViewHeightConstraint != nil && stepsTableViewHeightConstraint != nil {
          NSLayoutConstraint.deactivateConstraints([ingredientsTableViewHeightConstraint, stepsTableViewHeightConstraint])
        }

        // Set
        ingredientsTableViewHeightConstraint = ingredientsTableView.heightAnchor.constraintEqualToConstant(ingredientsTableView.contentSize.height)
        stepsTableViewHeightConstraint = stepsTableView.heightAnchor.constraintEqualToConstant(stepsTableView.contentSize.height)

        // Activate
        NSLayoutConstraint.activateConstraints([ingredientsTableViewHeightConstraint, stepsTableViewHeightConstraint])

        // Set the content size of the scroll view
        let finalSubview = editing ? tagTextField : tagsViewController.view
        scrollView.contentSize = CGSize(width: view.frame.width, height: finalSubview.frame.origin.y + finalSubview.frame.height + 8.0)
      }


    func addNewIngredientAmountToRecipe()
      {
        if let ingredientAmount = newIngredientAmount {
          // Insert the new managed objects into the context if necessary
          if ingredientAmount.ingredient.inserted == false {
            managedObjectContext.insertObject(ingredientAmount.ingredient)
          }
          if ingredientAmount.inserted == false {
            managedObjectContext.insertObject(ingredientAmount)
          }

          // Update the recipe
          recipe.ingredientAmounts.insert(ingredientAmount)

          // Set the new ingredient amount property to nil
          newIngredientAmount = nil
        }
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
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("selectImage:")))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        // Configure the ingredient table view
        ingredientsTableView = UITableView(frame: CGRect.zero)
        ingredientsTableView.bounces = false
        ingredientsTableView.delegate = self
        ingredientsTableView.dataSource = self
        ingredientsTableView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(ingredientsTableView)

        // Configure the step table view
        stepsTableView = UITableView(frame: CGRect.zero)
        stepsTableView.bounces = false
        stepsTableView.delegate = self
        stepsTableView.dataSource = self
        stepsTableView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stepsTableView)

        // Configure the tag view controller
        tagsViewController = TagsViewController(tags: recipe.tags, context: managedObjectContext)
        scrollView.addSubview(tagsViewController.view)

        // Configure the tag name text field
        tagTextField = UITextField(frame: CGRect.zero)
        tagTextField.borderStyle = .RoundedRect
        tagTextField.placeholder = "Tag name"
        tagTextField.textAlignment = .Center
        tagTextField.returnKeyType = .Done
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
        ingredientsTableView.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        ingredientsTableView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        ingredientsTableView.topAnchor.constraintEqualToAnchor(imageView.bottomAnchor, constant: 16.0).active = true

        // Configure the layout bindings for the step table view
        stepsTableView.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        stepsTableView.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        stepsTableView.topAnchor.constraintEqualToAnchor(ingredientsTableView.bottomAnchor, constant: 16.0).active = true

        // Configure the layout bindings for the tag view
        tagsViewController.view.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        tagsViewController.view.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        tagsViewController.view.heightAnchor.constraintEqualToConstant(100.0).active = true
        tagsViewController.view.topAnchor.constraintEqualToAnchor(stepsTableView.bottomAnchor, constant: 16.0).active = true

        // Configure the layout bindings for the tag text field
        tagTextField.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor, constant: -16.0).active = true
        tagTextField.centerXAnchor.constraintEqualToAnchor(scrollView.centerXAnchor).active = true
        tagTextField.heightAnchor.constraintEqualToConstant(30.0).active = true
        tagTextField.topAnchor.constraintEqualToAnchor(tagsViewController.view.bottomAnchor, constant: 8.0).active = true

        addIngredientButton = roundedSquareButton(self, action: "addIngredient:", controlEvents: .TouchUpInside, imageName: "addImage")
        collapseIngredientsButton = roundedSquareButton(self, action: "collapseIngredients:", controlEvents: .TouchUpInside, imageName: "collapseImage")
        addStepButton = roundedSquareButton(self, action: "addStep:", controlEvents: .TouchUpInside, imageName: "addImage")
        collapseStepsButton = roundedSquareButton(self, action: "collapseSteps:", controlEvents: .TouchUpInside, imageName: "collapseImage")
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
        super.viewWillLayoutSubviews()

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
        if tableView === ingredientsTableView && editingIngredientIndexPath == indexPath {
          dispatch_async(dispatch_get_main_queue())
              { () -> Void in
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! IngredientsTableViewCell
                cell.nameTextField.becomeFirstResponder()
              }
        }
      }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
      {
        switch tableView {
          case ingredientsTableView :
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return

          case stepsTableView :
            let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
            let stepViewController = StepViewController(step: step, editing: false, context: managedObjectContext)
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
            case ingredientsTableView :
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
          case ingredientsTableView :
            return newIngredientAmount == nil ? 1 : 2
          case stepsTableView :
            return 1
          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        switch tableView {
          case ingredientsTableView :
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
          case ingredientsTableView :
            // Either we're working with pre-existing ingredient amounts
            if indexPath.section == 0 {
              let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
              let cell = IngredientsTableViewCell(ingredientAmount: ingredientAmount, tableView: tableView)
              return cell
            }
            // Or we're creating a new ingredient amount
            else {
              let cell = IngredientsTableViewCell(ingredientAmount: newIngredientAmount!, tableView: tableView)
              return cell
            }

          case stepsTableView :
            let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
            let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
            cell.textLabel?.text = step.summary
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
          case ingredientsTableView :
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
          case ingredientsTableView :
            fatalError("ingredient amount reordering has not been implemented")

          case stepsTableView :
            // Get handles on the ingredient amounts we're going to be working with
            let sourceStep = recipe.steps.sort(stepsSortingBlock)[sourceIndexPath.row]
            let destinationStep = recipe.steps.sort(stepsSortingBlock)[destinationIndexPath.row]
            let movedSteps = recipe.steps.filter({ $0.number > sourceStep.number && $0.number <= destinationStep.number })

            let sourceNumber = sourceStep.number
            let destinationNumber = destinationStep.number

            // Update the ordering of the ingredients
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
        // If we previously created an ingredient amount which has not yet been inserted into the context
        if let ingredientAmount = newIngredientAmount {
          // We only want to add it if it is valid
          if ingredientAmount.ingredient.name != "" {
            addNewIngredientAmountToRecipe()
          }
          // Otherwise do nothing
          else {
            return
          }
        }

        // Create a new ingredient and ingredient amount, without inserting it into the context
        let newIngredient = Ingredient(name: "", context: managedObjectContext, insert: false)
        newIngredientAmount = IngredientAmount(ingredient: newIngredient, amount: "", number: Int16(recipe.ingredientAmounts.count), context: managedObjectContext, insert: false)
        editingIngredientIndexPath = NSIndexPath(forRow: 0, inSection: 1)

        ingredientsTableView.reloadData()

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
        let ingredients = self.ingredientsTableView

        // Either we're collapsing the table view
        if ingredientsTableView.frame.height == ingredientsTableView.contentSize.height {
          UIView.animateWithDuration(0.5, animations:
              { () -> Void in
                ingredients.frame = CGRect(x: ingredients.frame.origin.x, y: ingredients.frame.origin.y, width: ingredients.frame.width, height: self.collapseIngredientsButton.frame.height)
                ingredients.scrollEnabled = false
             },
            completion:
              { (compete: Bool) -> Void in
                self.ingredientsTableViewHeightConstraint = ingredients.heightAnchor.constraintEqualToConstant(self.collapseIngredientsButton.frame.height)
              })
        }
        // Or we're expanding it
        else {
          UIView.animateWithDuration(0.5, animations:
              { () -> Void in
                self.ingredientsTableViewHeightConstraint = ingredients.heightAnchor.constraintEqualToConstant(ingredients.contentSize.height)
                ingredients.frame = CGRect(x: ingredients.frame.origin.x, y: ingredients.frame.origin.y, width: ingredients.frame.width, height: ingredients.contentSize.height)
                ingredients.scrollEnabled = true
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
                tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.width, height: self.collapseStepsButton.frame.height)
                tableView.scrollEnabled = false
             },
            completion:
              { (compete: Bool) -> Void in
                self.stepsTableViewHeightConstraint = tableView.heightAnchor.constraintEqualToConstant(self.collapseStepsButton.frame.height)
              })
        }
        // Or we're expanding it
        else {
          UIView.animateWithDuration(0.5, animations:
              { () -> Void in
                self.stepsTableViewHeightConstraint = tableView.heightAnchor.constraintEqualToConstant(tableView.contentSize.height)
                tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.width, height: tableView.contentSize.height)
                tableView.scrollEnabled = true
             })
        }
      }

  }
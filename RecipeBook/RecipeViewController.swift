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

    var editingIngredientIndex: Int?


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
        scrollView.contentSize = CGSize(width: view.frame.width, height: tagTextField.frame.origin.y + tagTextField.frame.height + 8.0)
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

        // Configure button to add ingredients
        addIngredientButton = UIButton(type: .Custom)
        addIngredientButton.layer.cornerRadius = 5.0
        addIngredientButton.layer.borderWidth = 0.5
        addIngredientButton.layer.borderColor = UIColor.blackColor().CGColor
        addIngredientButton.showsTouchWhenHighlighted = true
        addIngredientButton.setTitle("+", forState: .Normal)
        addIngredientButton.addTarget(self, action: "addIngredient:", forControlEvents: .TouchUpInside)
        addIngredientButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        addIngredientButton.titleLabel!.textAlignment = .Center
        addIngredientButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure the button to collapse the ingredients table view
        collapseIngredientsButton = UIButton(type: .Custom)
        collapseIngredientsButton.layer.cornerRadius = 5.0
        collapseIngredientsButton.layer.borderWidth = 0.5
        collapseIngredientsButton.layer.borderColor = UIColor.blackColor().CGColor
        collapseIngredientsButton.showsTouchWhenHighlighted = true
        collapseIngredientsButton.setTitle(">", forState: .Normal)
        collapseIngredientsButton.addTarget(self, action: "collapseIngredients:", forControlEvents: .TouchUpInside)
        collapseIngredientsButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        collapseIngredientsButton.titleLabel!.textAlignment = .Center
        collapseIngredientsButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure button to add steps
        addStepButton = UIButton(type: .Custom)
        addStepButton.layer.cornerRadius = 5.0
        addStepButton.layer.borderWidth = 0.5
        addStepButton.layer.borderColor = UIColor.blackColor().CGColor
        addStepButton.showsTouchWhenHighlighted = true
        addStepButton.setTitle("+", forState: .Normal)
        addStepButton.addTarget(self, action: "addStep:", forControlEvents: .TouchUpInside)
        addStepButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        addStepButton.titleLabel!.textAlignment = .Center
        addStepButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure the button to collapse the ingredients table view
        collapseStepsButton = UIButton(type: .Custom)
        collapseStepsButton.layer.cornerRadius = 5.0
        collapseStepsButton.layer.borderWidth = 0.5
        collapseStepsButton.layer.borderColor = UIColor.blackColor().CGColor
        collapseStepsButton.showsTouchWhenHighlighted = true
        collapseStepsButton.setTitle(">", forState: .Normal)
        collapseStepsButton.addTarget(self, action: "collapseSteps:", forControlEvents: .TouchUpInside)
        collapseStepsButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        collapseStepsButton.titleLabel!.textAlignment = .Center
        collapseStepsButton.translatesAutoresizingMaskIntoConstraints = false
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
        textField.resignFirstResponder()
        return true;
      }


    func textFieldDidEndEditing(textField: UITextField)
      {
        switch textField {
          case nameTextField :
            recipe.name = textField.text!
          case tagTextField :
            tagsViewController.addTagWithName(textField.text!)
            textField.text = ""
          default :
            fatalError("unexpected text field")
        }

        imageView.userInteractionEnabled = true

        textField.resignFirstResponder()

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
        if tableView === ingredientsTableView && editingIngredientIndex == indexPath.row {
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


    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
      { return 30 }


    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        switch tableView {
          case ingredientsTableView :
            return recipe.ingredientAmounts.count

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
            let ingredientAmount = recipe.ingredientAmounts.sort(ingredientAmountsSortingBlock)[indexPath.row]
            let cell = IngredientsTableViewCell(ingredientAmount: ingredientAmount, tableView: tableView)
            return cell

          case stepsTableView :
            let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
            let step = recipe.steps.sort(stepsSortingBlock)[indexPath.row]
            cell.textLabel?.text = step.summary
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


    // MARK: - Actions

    override func save(sender: UIBarButtonItem)
      {
        super.save(sender)

        do { try managedObjectContext.save() }
        catch { fatalError("failed to save") }
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
        // Add am ingredient amount pair to our list
        let ingredient = Ingredient(name: "", context: managedObjectContext)
        editingIngredientIndex = recipe.ingredientAmounts.count
        let ingredientAmount = IngredientAmount(ingredient: ingredient, amount: "", number: Int16(editingIngredientIndex!), context: managedObjectContext)
        recipe.ingredientAmounts.insert(ingredientAmount)

        // Reload the table view, why does reloading the specific row not work?
        ingredientsTableView.reloadData()

        view.layoutSubviews()
      }


    func addStep(sender: AnyObject)
      {
        let step = Step(number: Int16(recipe.steps.count), summary: "", detail: "", imageData: nil, context: managedObjectContext)
        let stepViewController = StepViewController(step: step, editing: true, context: managedObjectContext)
            { (step: Step) -> Void in
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
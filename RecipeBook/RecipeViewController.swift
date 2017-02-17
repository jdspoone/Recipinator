/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class RecipeViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource
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
        willSet { willChangeValue(forKey: "ingredientsExpanded") }
        didSet { didChangeValue(forKey: "ingredientsExpanded") }
      }

    var stepsTableView: UITableView!
    var stepsExpanded: Bool = true
      {
        // Enable key-value observation
        willSet { willChangeValue(forKey: "stepsExpanded") }
        didSet { didChangeValue(forKey: "stepsExpanded") }
      }

    var tagsViewController: TagsViewController!

    var newIngredientAmount = false

    var editingIngredientIndexPath: IndexPath?


    var ingredientAmountsTableViewHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if ingredientAmountsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivate([ingredientAmountsTableViewHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activate([ingredientAmountsTableViewHeightConstraint])
        }
      }

    var stepsTableViewHeightConstraint: NSLayoutConstraint!
      {
        // Deactivate the old constraint if applicable
        willSet {
          if stepsTableViewHeightConstraint != nil {
            NSLayoutConstraint.deactivate([stepsTableViewHeightConstraint])
          }
        }
        // Activate the new constraint
        didSet {
          NSLayoutConstraint.activate([stepsTableViewHeightConstraint])
        }
      }


    var addIngredientButton: UIButton!
    var collapseIngredientsButton: UIButton!
    var addStepButton: UIButton!
    var collapseStepsButton: UIButton!


    // MARK: -

    init(recipe: Recipe, editing: Bool, context: NSManagedObjectContext, completion: @escaping (Recipe) -> Void)
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
        let cell = ingredientAmountsTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! IngredientAmountTableViewCell
        let name = cell.nameTextField.text!
        let amount = cell.amountTextField.text!

        // Create a new ingredient and ingredientAmount, and add it to the recipe
        let ingredient = Ingredient.withName(name, inContext: managedObjectContext)
        let ingredientAmount = IngredientAmount(ingredient: ingredient, amount: amount, number: Int16(recipe.ingredientAmounts.count), context: managedObjectContext)
        recipe.ingredientAmounts.insert(ingredientAmount)

        // Set the newIngredientAmount flag to false
        newIngredientAmount = false

        // Reload the tableView
        ingredientAmountsTableView.reloadData()
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
        nameTextField.textAlignment = .center
        nameTextField.returnKeyType = .done
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

        // Configure the tag view controller
        tagsViewController = TagsViewController(tags: recipe.tags, context: managedObjectContext)
        addChildViewController(tagsViewController)
        addSubviewToScrollView(tagsViewController.view)

        // Configure the layout bindings for the text field
        nameTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        nameTextField.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        nameTextField.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the image view
        imageViewController.view.widthAnchor.constraint(equalToConstant: 320.0).isActive = true
        imageViewController.view.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        imageViewController.view.heightAnchor.constraint(equalToConstant: 320.0).isActive = true
        imageViewController.view.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the ingredient table view
        ingredientAmountsTableView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        ingredientAmountsTableView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        ingredientAmountsTableView.topAnchor.constraint(equalTo: imageViewController.view.bottomAnchor, constant: 16.0).isActive = true

        // Configure the layout bindings for the step table view
        stepsTableView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        stepsTableView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        stepsTableView.topAnchor.constraint(equalTo: ingredientAmountsTableView.bottomAnchor, constant: 16.0).isActive = true

        // Configure the layout bindings for the tag view
        tagsViewController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        tagsViewController.view.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        tagsViewController.view.heightAnchor.constraint(equalToConstant: 200.0).isActive = true
        tagsViewController.view.topAnchor.constraint(equalTo: stepsTableView.bottomAnchor, constant: 16.0).isActive = true

        addIngredientButton = roundedSquareButton(self, action: #selector(RecipeViewController.addIngredient(_:)), controlEvents: .touchUpInside, imageName: "addImage")
        collapseIngredientsButton = roundedSquareButton(self, action: #selector(RecipeViewController.toggleIngredientsVisibility(_:)), controlEvents: .touchUpInside, imageName: "collapseImage")
        addStepButton = roundedSquareButton(self, action: #selector(RecipeViewController.addStep(_:)), controlEvents: .touchUpInside, imageName: "addImage")
        collapseStepsButton = roundedSquareButton(self, action: #selector(RecipeViewController.toggleStepsVisibility(_:)), controlEvents: .touchUpInside, imageName: "collapseImage")
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        restoreState()
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom notifications
        observations = [
          Observation(source: self, keypaths: ["editing"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.nameTextField.isUserInteractionEnabled = self.isEditing
                self.nameTextField.borderStyle = self.isEditing ? .roundedRect : .none
                self.imageViewController.setUserInteractionEnabled(self.isEditing && self.activeSubview == nil)
                self.addIngredientButton.isHidden = self.isEditing && self.ingredientsExpanded ? false : true
                self.addStepButton.isHidden = self.isEditing && self.stepsExpanded ? false : true
              }),
          Observation(source: self, keypaths: ["activeSubview"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.imageViewController.setUserInteractionEnabled(self.isEditing && self.activeSubview == nil)
              }),
          Observation(source: self, keypaths: ["ingredientsExpanded"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.addIngredientButton.isHidden = self.isEditing && self.ingredientsExpanded ? false : true
              }),
          Observation(source: self, keypaths: ["stepsExpanded"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.addStepButton.isHidden = self.isEditing && self.stepsExpanded ? false : true
              }),
          Observation(source: ingredientAmountsTableView, keypaths: ["contentSize"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.ingredientAmountsTableViewHeightConstraint = self.ingredientAmountsTableView.heightAnchor.constraint(equalToConstant: self.ingredientAmountsTableView.contentSize.height)
              }),
          Observation(source: stepsTableView, keypaths: ["contentSize"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in
                self.stepsTableViewHeightConstraint = self.stepsTableView.heightAnchor.constraint(equalToConstant: self.stepsTableView.contentSize.height)
              }),
          Observation(source: tagsViewController, keypaths: ["tags"], options: NSKeyValueObservingOptions(), block:
              { (change: [NSKeyValueChangeKey : Any]?) -> Void in
                self.recipe.tags = self.tagsViewController.tags
              }),
          Observation(source: imageViewController, keypaths: ["image"], options: .initial, block:
              { (change: [NSKeyValueChangeKey : Any]?) -> Void in
                self.recipe.image = self.imageViewController.image
              })
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // Execute the completion block if we're moving from the parent view controller
        if isMovingFromParentViewController {
          completion(recipe)
        }
      }


    override func viewDidLayoutSubviews()
      {
        super.viewDidLayoutSubviews()

        // Update the content size of the scroll view
        updateScrollViewContentSize()
      }


    override func setEditing(_ editing: Bool, animated: Bool)
      {
        super.setEditing(editing, animated: animated)

        // Set the editing state of the various table views
        stepsTableView.setEditing(editing, animated: animated)
        tagsViewController.setEditing(editing, animated: animated)
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
      {
        textField.resignFirstResponder()
        return true
      }


    override func textFieldDidEndEditing(_ textField: UITextField)
      {
        // As along as the textField is the activeSubview
        if activeSubview === textField {

          // Switch on the textField
          switch textField {

            // If it's the nameTextField, update the recipe's name
            case nameTextField:
              if let text = textField.text {
                recipe.name = text
              }
              break;

            // Otherwise, break
            default:
              break;
          }
        }

        super.textFieldDidEndEditing(textField)
      }


    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
      {
        // If we're about to show the newly created ingredient cell
        if tableView === ingredientAmountsTableView && editingIngredientIndexPath == indexPath {
          DispatchQueue.main.async
              { () -> Void in
                let cell = tableView.cellForRow(at: indexPath) as! IngredientAmountTableViewCell
                cell.nameTextField.becomeFirstResponder()
              }
        }
      }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
      {
        switch tableView {
          case ingredientAmountsTableView :
            // Do nothing
            tableView.deselectRow(at: indexPath, animated: true)
            return

          case stepsTableView :
            // Get the list of steps, and the index of the step we're interested in
            let steps = recipe.steps.sorted(by: stepsSortingBlock)
            let index = indexPath.row
            let step = steps[index]
            // Present a steps view controller
            let stepsViewController = StepsViewController(steps: steps, index: index, editing: isEditing, context: managedObjectContext, completion:
              { () in
                // Update the label of the tableView cell
                let cell = tableView.cellForRow(at: indexPath)!
                cell.textLabel!.text = step.summary != "" ? step.summary : NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"
              })
            show(stepsViewController, sender: self)
            tableView.deselectRow(at: indexPath, animated: true)

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
      {
        if section == 0 {
          let view = UIView(frame: CGRect.zero)
          view.backgroundColor = UIColor.white

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

          label.textAlignment = .center
          label.translatesAutoresizingMaskIntoConstraints = false
          view.addSubview(label)

          leftButton.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
          leftButton.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
          leftButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
          leftButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true

          rightButton.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
          rightButton.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
          rightButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
          rightButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

          label.leftAnchor.constraint(equalTo: leftButton.rightAnchor).isActive = true
          label.rightAnchor.constraint(equalTo: rightButton.leftAnchor).isActive = true
          label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
          label.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

          return view
        }
        return nil
      }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
      { return section == 0 ? 30 : 0 }


    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
      {
        // Schedule a call to updateScrollViewContentSize after a slight delay
        perform(#selector(BaseViewController.updateScrollViewContentSize), with: nil, afterDelay: 0.1)
      }


    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int
      {
        switch tableView {

          case ingredientAmountsTableView :
            return 1

          case stepsTableView :
            return 1

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        switch tableView {

          case ingredientAmountsTableView :
            return recipe.ingredientAmounts.count;

          case stepsTableView :
            return recipe.steps.count

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
      {
        // Switch on the tableView
        switch tableView {

          case ingredientAmountsTableView :
            // Return an IngredientAmountTableViewCell for the appropriate IngredientAmount
            let ingredientAmount = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[indexPath.row]
            return IngredientAmountTableViewCell(parentTableView: tableView, ingredientAmount: ingredientAmount)

          case stepsTableView :
            // Configure and return a tableViewCell for the appropriate Step
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let step = recipe.steps.sorted(by: stepsSortingBlock)[indexPath.row]
            cell.textLabel!.text = step.summary != "" ? step.summary : NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"
            cell.textLabel!.font = UIFont(name: "Helvetica", size: 16)
            cell.showsReorderControl = true
            return cell

          default :
            fatalError("unexpected table view")
        }
      }


    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
      {
        // We only want to be able to edit tableViews when we aren't currently editing some text
        return isEditing && activeSubview == nil
      }


    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
      {
        // We only expect to be modifying the table views when we're in editing mode
        assert(isEditing == true, "unexpected state")

        // Begin the animation block
        tableView.beginUpdates()

        // Remove the appropriate row from the tableView
        tableView.deleteRows(at: [indexPath], with: .automatic)

        switch tableView {
          case ingredientAmountsTableView :
            // Delete the selected ingredientAmount
            if editingStyle == .delete {
              let ingredientAmount = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[indexPath.row]
              recipe.ingredientAmounts.remove(ingredientAmount)
              managedObjectContext.delete(ingredientAmount)
            }
          case stepsTableView :
            // Delete the selected step
            if editingStyle == .delete {
              let step = recipe.steps.sorted(by: stepsSortingBlock)[indexPath.row]
              recipe.steps.remove(step)
              managedObjectContext.delete(step)
            }
          default :
            fatalError("unexpected table view")
        }

        // End the animation block
        tableView.endUpdates()
      }


    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
      { return isEditing }


    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
      {
        switch tableView {
          case ingredientAmountsTableView :
            fatalError("ingredient amount reordering has not been implemented")

          case stepsTableView :
            // Get handles on the steps and step numbers we're going to be working with
            let sourceStep = recipe.steps.sorted(by: stepsSortingBlock)[sourceIndexPath.row]
            let sourceNumber = sourceStep.number

            let destinationStep = recipe.steps.sorted(by: stepsSortingBlock)[destinationIndexPath.row]
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

    override func save(_ sender: AnyObject?)
      {
        // Call super's implementation
        super.save(sender)

        // Attempt to save the managedObjectContext
        do { try managedObjectContext.save() }
        catch { fatalError("failed to save") }
      }


    func alertTextFieldDidChange(_ textField: UITextField)
      {
        if let alertController = presentedViewController as? UIAlertController {
          let submitAction = alertController.actions.last!
          submitAction.isEnabled = textField.text != nil
            ? (textField.text?.characters.count)! > 0
            : false
        }
      }


    func addIngredient(_ sender: AnyObject)
      {
        assert(ingredientsExpanded, "Unexpected state - ingredients table view is collapsed")

        // Configure a UIAlertController
        let alertController = UIAlertController(title: NSLocalizedString("NEW INGREDIENT", comment: ""), message: NSLocalizedString("ENTER THE NAME OF THE NEW INGREDIENT", comment: ""), preferredStyle: .alert)

        // Add a textField to the alertController for the ingredient's name
        alertController.addTextField(configurationHandler:
            { (textField: UITextField) in
              textField.placeholder = "Ingredient"
              textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: .editingChanged)
            })

        // Add a cancel button to the alertController
        alertController.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil))

        // Add a submit action to the alertController
        let submitAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler:
            { (action: UIAlertAction) in
              // Get the name of the ingredient from the textField
              let name = alertController.textFields!.last!.text!

              // Create a new ingredient and ingredientAmount, and add it to the recipe
              let ingredient = Ingredient.withName(name, inContext: self.managedObjectContext)
              let ingredientAmount = IngredientAmount(ingredient: ingredient, amount: "", number: Int16(self.recipe.ingredientAmounts.count), context: self.managedObjectContext)
              self.recipe.ingredientAmounts.insert(ingredientAmount)

              // Update the ingredientAmountTableView
              self.ingredientAmountsTableView.reloadData()
            })
        submitAction.isEnabled = false;
        alertController.addAction(submitAction)

        // Present the alertController
        present(alertController, animated: true, completion: nil);
      }


    func addStep(_ sender: AnyObject)
      {
        assert(stepsExpanded, "Unexpected state - steps table view is collapsed")

        let step = Step(number: Int16(recipe.steps.count), summary: "", detail: "", imageData: nil, context: managedObjectContext, insert: false)
        let stepViewController = StepViewController(step: step, editing: true, context: managedObjectContext)
            { (step: Step) -> Void in

              // Begin the animation block
              self.stepsTableView.beginUpdates()

              // Insert the returned step into the managed object context, and update the recipe
              self.managedObjectContext.insert(step)
              self.recipe.steps.insert(step)

              do { try self.managedObjectContext.save() }
              catch { fatalError("failed to save") }

              // Insert a new row into the table view
              let indexPath = IndexPath(row: Int(step.number), section: 0)
              self.stepsTableView.insertRows(at: [indexPath], with: .automatic)

              // End the animation block
              self.stepsTableView.endUpdates()
            }
        show(stepViewController, sender: self)
      }


    func toggleIngredientsVisibility(_ sender: AnyObject)
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

        UIView.animate(withDuration: 0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseIngredientsButton.imageView!.transform = CGAffineTransform(rotationAngle: 0)
              // Expand the tableview
              self.ingredientAmountsTableViewHeightConstraint = ingredients?.heightAnchor.constraint(equalToConstant: (ingredients?.contentSize.height)!)
              ingredients?.frame = CGRect(x: (ingredients?.frame.origin.x)!, y: (ingredients?.frame.origin.y)!, width: (ingredients?.frame.width)!, height: (ingredients?.contentSize.height)!)
              ingredients?.isScrollEnabled = true
           },
          completion:
            { (complete: Bool) -> Void in
              // Adjust the content size of the scroll view
              self.ingredientsExpanded = true
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height + ((ingredients?.contentSize.height)! - self.collapseIngredientsButton.frame.height))
            })
      }


    func collapseIngredients()
      {
        let ingredients = self.ingredientAmountsTableView

        UIView.animate(withDuration: 0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseIngredientsButton.imageView!.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
              // Collapse the tableview
              ingredients?.frame = CGRect(x: (ingredients?.frame.origin.x)!, y: (ingredients?.frame.origin.y)!, width: (ingredients?.frame.width)!, height: self.collapseIngredientsButton.frame.height)
              ingredients?.isScrollEnabled = false
           },
          completion:
            { (compete: Bool) -> Void in
              // Update the height contraint of the ingredient amounts table view, and adjust the content size of the scroll view
              self.ingredientsExpanded = false
              self.ingredientAmountsTableViewHeightConstraint = ingredients?.heightAnchor.constraint(equalToConstant: self.collapseIngredientsButton.frame.height)
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height - ((ingredients?.contentSize.height)! - self.collapseIngredientsButton.frame.height))
            })
      }


    func toggleStepsVisibility(_ sender: AnyObject)
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

        UIView.animate(withDuration: 0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseStepsButton.imageView!.transform = CGAffineTransform(rotationAngle: 0)
              // Expand the tableview
              self.stepsTableViewHeightConstraint = tableView?.heightAnchor.constraint(equalToConstant: (tableView?.contentSize.height)!)
              tableView?.frame = CGRect(x: (tableView?.frame.origin.x)!, y: (tableView?.frame.origin.y)!, width: (tableView?.frame.width)!, height: (tableView?.contentSize.height)!)
              tableView?.isScrollEnabled = true
           }, completion:
            { (complete: Bool) -> Void in
              // Adjust the content size of the scroll view
              self.stepsExpanded = true
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height + ((tableView?.contentSize.height)! - self.collapseStepsButton.frame.height))
            })
      }


    func collapseSteps()
      {
        let tableView = self.stepsTableView

        UIView.animate(withDuration: 0.5, animations:
            { () -> Void in
              // Rotate the button
              self.collapseStepsButton.imageView!.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
              // Collapse the table view
              tableView?.frame = CGRect(x: (tableView?.frame.origin.x)!, y: (tableView?.frame.origin.y)!, width: (tableView?.frame.width)!, height: self.collapseStepsButton.frame.height)
              tableView?.isScrollEnabled = false
           },
          completion:
            { (compete: Bool) -> Void in
              // Update the height contraint of the steps table view, and adjust the content size of the scroll view
              self.stepsExpanded = false
              self.stepsTableViewHeightConstraint = tableView?.heightAnchor.constraint(equalToConstant: self.collapseStepsButton.frame.height)
              self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.contentSize.height - ((tableView?.contentSize.height)! - self.collapseStepsButton.frame.height))
            })
      }

  }

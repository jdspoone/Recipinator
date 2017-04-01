/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class RecipeViewController: BaseViewController, NSFetchedResultsControllerDelegate, UIViewControllerPreviewingDelegate, UITableViewDelegate, UITableViewDataSource
  {

    var recipe: Recipe

    var previewingContext: UIViewControllerPreviewing?

    let imageSortingBlock: (Image, Image) -> Bool = { $0.index < $1.index }
    let ingredientAmountsSortingBlock: (IngredientAmount, IngredientAmount) -> Bool = { $0.number < $1.number }
    let stepsSortingBlock: (Step, Step) -> Bool = { return $0.number < $1.number }

    var nameTextField: UITextField!

    var imagesFetchedResultsController: NSFetchedResultsController<Image>!
    var imagePreviewPageViewController: ImagePreviewPageViewController!

    var ingredientAmountsTableView: UITableView!
    let ingredientAmountsReuseIdentifier = "IngredientAmountsTableViewCell"
    var ingredientsExpanded: Bool = true
      {
        // Enable key-value observation
        willSet { willChangeValue(forKey: "ingredientsExpanded") }
        didSet { didChangeValue(forKey: "ingredientsExpanded") }
      }

    var stepsTableView: UITableView!
    let stepsTableViewReuseIdentifier = "StepsTableViewCell"
    var stepsExpanded: Bool = true
      {
        // Enable key-value observation
        willSet { willChangeValue(forKey: "stepsExpanded") }
        didSet { didChangeValue(forKey: "stepsExpanded") }
      }

    var tagsViewController: TagsViewController!


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

    init(recipe: Recipe, editing: Bool, context: NSManagedObjectContext)
      {
        self.recipe = recipe

        super.init(editing: editing, context: context)
      }


    func restoreState()
      {
        nameTextField.text = recipe.name
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

        // Configure the image preview page view controller
        imagePreviewPageViewController = ImagePreviewPageViewController(images: recipe.images)
        addChildViewController(imagePreviewPageViewController)
        imagePreviewPageViewController.didMove(toParentViewController: self)
        let imagePreview = imagePreviewPageViewController.view!
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(imagePreview)

        // Configure the ingredient table view
        ingredientAmountsTableView = UITableView(frame: CGRect.zero)
        ingredientAmountsTableView.cellLayoutMarginsFollowReadableWidth = false;
        ingredientAmountsTableView.bounces = false
        ingredientAmountsTableView.rowHeight = 50
        ingredientAmountsTableView.allowsSelectionDuringEditing = true
        ingredientAmountsTableView.delegate = self
        ingredientAmountsTableView.dataSource = self
        ingredientAmountsTableView.register(IngredientAmountTableViewCell.self, forCellReuseIdentifier: ingredientAmountsReuseIdentifier)
        ingredientAmountsTableView.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(ingredientAmountsTableView)

        // Configure the step table view
        stepsTableView = UITableView(frame: CGRect.zero)
        stepsTableView.cellLayoutMarginsFollowReadableWidth = false;
        stepsTableView.bounces = false
        stepsTableView.rowHeight = 50
        stepsTableView.allowsSelectionDuringEditing = true
        stepsTableView.delegate = self
        stepsTableView.dataSource = self
        stepsTableView.register(UITableViewCell.self, forCellReuseIdentifier: stepsTableViewReuseIdentifier)
        stepsTableView.translatesAutoresizingMaskIntoConstraints = false
        addSubviewToScrollView(stepsTableView)

        // Configure the tag view controller
        tagsViewController = TagsViewController(tags: recipe.tags, context: managedObjectContext)
        addChildViewController(tagsViewController)
        tagsViewController.didMove(toParentViewController: self)
        addSubviewToScrollView(tagsViewController.view)

        // Configure the layout bindings for the text field
        nameTextField.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        nameTextField.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        nameTextField.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the image preview
        imagePreview.widthAnchor.constraint(equalToConstant: 320.0).isActive = true
        imagePreview.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        imagePreview.heightAnchor.constraint(equalToConstant: 320.0).isActive = true
        imagePreview.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8.0).isActive = true

        // Configure the layout bindings for the ingredient table view
        ingredientAmountsTableView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        ingredientAmountsTableView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        ingredientAmountsTableView.topAnchor.constraint(equalTo: imagePreview.bottomAnchor, constant: 16.0).isActive = true

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

        // Configure the images fetch request
        let imagesFetchRequest = NSFetchRequest<Image>(entityName: "Image")
        imagesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        imagesFetchRequest.predicate = NSPredicate(format: "%K  == %@", argumentArray: ["recipeUsedIn", recipe.objectID])

        // Configure the images fetched results controller
        imagesFetchedResultsController = NSFetchedResultsController(fetchRequest: imagesFetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        imagesFetchedResultsController.delegate = self

        // Attempt to fetch the images associated with this recipe
        do {
          try imagesFetchedResultsController.performFetch()
        }
        catch let e { fatalError("error: \(e)") }

        // Configure a gesture recognizer on the image preview view controller
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectImage(_:)))
        imagePreviewPageViewController.view!.addGestureRecognizer(gestureRecognizer)

        // Enable previewing if applicable
        togglePreviewing()

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
                self.addIngredientButton.isHidden = self.isEditing && self.ingredientsExpanded ? false : true
                self.addStepButton.isHidden = self.isEditing && self.stepsExpanded ? false : true
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
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // If we're moving from the parent view controller, end editing
        if isMovingFromParentViewController {
          endEditing(self)
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
        ingredientAmountsTableView.setEditing(editing, animated: animated)
        stepsTableView.setEditing(editing, animated: animated)
        tagsViewController.setEditing(editing, animated: animated)
      }


    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
      {
        // Switch on the controller
        switch controller {

          case imagesFetchedResultsController:
            // Update the image preview view controller
            imagePreviewPageViewController.updateImages(newImages: recipe.images)

          default:
            fatalError("unexpected fetched results controller")
        }
      }


    // MARK: - UIViewControllerPreviewingDelegate

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
      {
        // Get the location of the press
        let position = stepsTableView.convert(location, from: self.view)

        // If there is a table view cell at the given location
        if let path = stepsTableView.indexPathForRow(at: position) {

          // Create a steps view controller for the selected recipe
          let steps = recipe.steps.sorted(by: stepsSortingBlock)
          let stepsViewController = StepsViewController(steps: steps, index: path.row, editing: isEditing, context: managedObjectContext, completion:
            { (step: Step) in
              // Update the label of the tableView cell
              let cell = self.stepsTableView.cellForRow(at: IndexPath(row: Int(step.number), section: 0))!
              cell.textLabel!.text = step.summary != "" ? step.summary : NSLocalizedString("STEP", comment: "") + " \(step.number + 1)"
            })

          // Set the source rect of the previewing context to be the frame of the selected cell
          let cell = stepsTableView.cellForRow(at: path)!
          previewingContext.sourceRect = view.convert(cell.frame, from: stepsTableView)

          // Return the steps view controller
          return stepsViewController
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
        textField.resignFirstResponder()
        return true
      }


    override func textFieldDidEndEditing(_ textField: UITextField)
      {
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

        super.textFieldDidEndEditing(textField)
      }


    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
      {
        switch tableView {
          case ingredientAmountsTableView :
            // Get the ingredient amount that was just selected
            let ingredientAmount = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[indexPath.row]

            // Edit that ingredient amount
            editIngredientAmount(ingredientAmount, at: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)

          case stepsTableView :
            // Get the list of steps, and the index of the step we're interested in
            let steps = recipe.steps.sorted(by: stepsSortingBlock)
            let index = indexPath.row

            // Present a steps view controller
            let stepsViewController = StepsViewController(steps: steps, index: index, editing: isEditing, context: managedObjectContext, completion:
              { (step: Step) in
                // Update the label of the tableView cell
                let cell = tableView.cellForRow(at: IndexPath(row: Int(step.number), section: 0))!
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
            // Dequeue and configure a table view cell for the ingredient amount
            let cell = tableView.dequeueReusableCell(withIdentifier: ingredientAmountsReuseIdentifier)!
            let ingredientAmount = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[indexPath.row]
            cell.textLabel!.text = ingredientAmount.ingredient.name

            if ingredientAmount.amount != "" {
              cell.detailTextLabel!.text = ingredientAmount.amount
              cell.detailTextLabel!.textColor = .black
              cell.detailTextLabel!.font = UIFont.systemFont(ofSize: 17)
            }
            else {
              cell.detailTextLabel!.text = "Amount"
              cell.detailTextLabel!.textColor = .lightGray
              cell.detailTextLabel!.font = UIFont.italicSystemFont(ofSize: 17)
            }

            return cell

          case stepsTableView :
            // Dequeue and configure a table view cell for the step
            let cell = tableView.dequeueReusableCell(withIdentifier: stepsTableViewReuseIdentifier)!
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

            if editingStyle == .delete {
              // Delete the selected ingredient amount
              let selected = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[indexPath.row]
              recipe.ingredientAmounts.remove(selected)
              managedObjectContext.delete(selected)

              // Iterate over the remaining ingredient amounts
              for (index, ingredientAmount) in recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock).enumerated() {
                // Update the the remaining ingredient amounts
                if ingredientAmount.number != Int16(index) {
                  ingredientAmount.number = Int16(index)
                }
              }

            }
          case stepsTableView :
            if editingStyle == .delete {

              // Delete the selected step
              let selected = recipe.steps.sorted(by: stepsSortingBlock)[indexPath.row]
              recipe.steps.remove(selected)
              managedObjectContext.delete(selected)

              // Iterate over the remaining steps
              for (index, step) in recipe.steps.sorted(by: stepsSortingBlock).enumerated() {
                // Update the remaining steps
                if step.number != Int16(index) {
                  step.number = Int16(index)
                }
              }
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
            // Get handles on the ingredient amounts we're going to be working with
            let sourceIngredientAmount = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[sourceIndexPath.row]
            let sourceNumber = sourceIngredientAmount.number

            let destinationIngredientAmount = recipe.ingredientAmounts.sorted(by: ingredientAmountsSortingBlock)[destinationIndexPath.row]
            let destinationNumber = destinationIngredientAmount.number

            // Determine which ingredient amounts will be affected by the reordering
            let movedIngredientAmounts = recipe.ingredientAmounts.filter({ return sourceNumber < destinationNumber ? $0.number <= destinationNumber && $0.number > sourceNumber : $0.number >= destinationNumber && $0.number < sourceNumber })

            // Update the order of the steps
            sourceIngredientAmount.number = destinationIngredientAmount.number
            for ingredientAmount in movedIngredientAmounts {
              ingredientAmount.number += sourceNumber < destinationNumber ? -1 : 1
            }

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

    func selectImage(_ sender: AnyObject?)
      {
        // Ensure the active subview resigns as first responder
        activeSubview?.resignFirstResponder()

        // If we're editing, or if the recipe has no images
        if isEditing || recipe.images.count == 0 {
          // Configure and show an ImageCollectionViewController
          let imageCollectionViewController = ImageCollectionViewController(images: recipe.images, imageOwner: recipe, editing: true, context: managedObjectContext)
          show(imageCollectionViewController, sender: self)
        }
        // Otherwise, show an ImagePageViewController
        else {
          let imagePageViewController = ImagePageViewController(images: recipe.images, index: imagePreviewPageViewController.currentIndex!)
          show(imagePageViewController, sender: self)
        }
      }


    func ingredientNameDidChange(_ textField: UITextField)
      {
        if let alertController = presentedViewController as? UIAlertController {
          let submitAction = alertController.actions.last!
          submitAction.isEnabled = textField.text != nil ? (textField.text?.characters.count)! > 0 : false
        }
      }


    func editIngredientAmount(_ ingredientAmount: IngredientAmount? = nil, at indexPath: IndexPath?  = nil)
      {
        // Sanity check
        assert(ingredientsExpanded, "Unexpected state - ingredients table view is collapsed")

        // Configure an alert controller
        let alertController = UIAlertController(title: NSLocalizedString(ingredientAmount == nil ? "NEW INGREDIENT" : "EDIT INGREDIENT", comment: ""), message: nil, preferredStyle: .alert)

        // Add a text field to the controller for the ingredient name
        alertController.addTextField(configurationHandler:
            { (textField: UITextField) in
              textField.text = ingredientAmount?.ingredient.name
              textField.placeholder = NSLocalizedString("INGREDIENT", comment: "")
              textField.textAlignment = .center
              textField.addTarget(self, action: #selector(self.ingredientNameDidChange(_:)), for: .editingChanged)
            })

        // Add a text field to the controller for the ingredient amount
        alertController.addTextField(configurationHandler:
            { (textField: UITextField) in
              textField.text = ingredientAmount?.amount
              textField.placeholder = NSLocalizedString("AMOUNT", comment: "")
              textField.textAlignment = .center
            })

        // Add a cancel button
        alertController.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil))

        // Add a submit action to the alertController
        let submitAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler:
            { (action: UIAlertAction) in

              // Get the name and amount of the ingredient
              let name = alertController.textFields!.first!.text!
              let amount = alertController.textFields!.last!.text!

              // Sanity check
              assert(name != "", "unexpected state")

              // Get the ingredient associated with the ingredient amount
              let ingredient = Ingredient.withName(name, inContext: self.managedObjectContext)

              // If we weren't given an ingredient amount as a parameter, create one and add it to the recipe
              if ingredientAmount == nil {
                let newIngredientAmount = IngredientAmount(ingredient: ingredient, amount: amount, number: Int16(self.recipe.ingredientAmounts.count), context: self.managedObjectContext)
                self.recipe.ingredientAmounts.insert(newIngredientAmount)
              }
              // Otherwise update the existing ingredient amount
              else {
                ingredientAmount!.ingredient = ingredient
                ingredientAmount!.amount = amount
              }

              // If we're editing an existing ingredient amount, reload the row at the given index path
              if let indexPath = indexPath {
                self.ingredientAmountsTableView.reloadRows(at: [indexPath], with: .none)
              }
              // Otherwise, insert a new row at the end of the table view for the new ingredient amount
              else {
                let newIndexPath = IndexPath(row: self.recipe.ingredientAmounts.count - 1, section: 0)
                self.ingredientAmountsTableView.insertRows(at: [newIndexPath], with: .none)
              }
            })
        // The submit action should only be initially enabled if we're editing an existing ingredient amount
        submitAction.isEnabled = ingredientAmount != nil;
        alertController.addAction(submitAction)

        // Present the alertController
        present(alertController, animated: true, completion: nil)
      }


    func addIngredient(_ sender: AnyObject?)
      {
        // Create a new ingredient amount
        editIngredientAmount()
      }


    func addStep(_ sender: AnyObject?)
      {
        assert(stepsExpanded, "Unexpected state - steps table view is collapsed")

        // Create a new step, and add it to the recipe's set of steps
        let step = Step(number: Int16(recipe.steps.count), summary: "", detail: "", images: [], context: managedObjectContext)
        recipe.steps.insert(step)

        // Configure and show a StepViewController for the new step
        let stepViewController = StepViewController(step: step, editing: true, context: managedObjectContext)
            { (step: Step) -> Void in

              // Begin the animation block
              self.stepsTableView.beginUpdates()

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
        // As long as the recipe has some ingredientAmounts
        if recipe.ingredientAmounts.count > 0 {
          if ingredientAmountsTableView.frame.height == ingredientAmountsTableView.contentSize.height {
            collapseIngredients()
          }
          else {
            expandIngredients()
          }
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


    func toggleStepsVisibility(_ sender: AnyObject?)
      {
        // As long as the recipe has some steps
        if recipe.steps.count > 0 {
          if stepsTableView.frame.height == stepsTableView.contentSize.height {
            collapseSteps()
          }
          else {
            expandSteps()
          }
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

/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class TagsViewController: UIViewController, UITextFieldDelegate
  {

    var observations = Set<Observation>()

    var titleLabel: UILabel!
    var tagsView: UIView!
    var tagTextField: UITextField!

    var tags: Set<Tag>
    var managedObjectContext: NSManagedObjectContext

    var tagViewDictionary: [Tag: TagView] = [:]
    var tagViewArrangement: [[TagView]] = [[]]

    let sortingBlock: (Tag, Tag) -> Bool =
        { (a: Tag, b: Tag) -> Bool in
          return a.name < b.name
        }

    let tagViewSpacing: CGFloat = 5.0

    var recipeViewController: RecipeViewController
      {
        return parent as! RecipeViewController
      }


    init(tags: Set<Tag>, context: NSManagedObjectContext)
      {
        self.tags = tags
        self.managedObjectContext = context

        super.init(nibName: nil, bundle: nil)
      }


    func shouldCreateTagWithName(_ name: String) -> Bool
      {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        request.predicate = NSPredicate(format: "name = %@", name)

        var results: [Tag] = []
        do { results = try managedObjectContext.fetch(request) as! [Tag] }
        catch let e { fatalError("error: \(e)") }

        if results.count == 0 {
          return true
        }
        else {
          assert(results.count == 1, "unexpected state - multiple tags with name: \(name)")
          return false
        }
      }


    func addTagWithName(_ name: String)
      {
        // Get a tag object for the given name
        let tag = Tag.withName(name, inContext: managedObjectContext)

        // Add the tag to the set of tags, if it is not already in there
        if tags.contains(tag) == false {
          willChangeValue(forKey: "tags", withSetMutation: .union, using: [tag])
          tags.insert(tag)
          didChangeValue(forKey: "tags", withSetMutation: .union, using: [tag])

          let tagView = TagView(tag: tag, editing: isEditing, controller: self)
          tagsView.addSubview(tagView)

          tagViewDictionary[tag] = tagView

          updateSubviewConstraints()
        }
      }


    func removeTag(_ tag: Tag)
      {
        // Remove the given tag from our set of tags and the recipe it was attached to
        tags.remove(tag)
        recipeViewController.recipe.tags.remove(tag)

        // Remove the view for the tag
        tagViewDictionary[tag]!.removeFromSuperview()

        // Update the constraints of the subviews
        updateSubviewConstraints()

        // Ensure we don't have any orphan Tags hanging about
        if tag.objectIDs(forRelationshipNamed: "recipesUsedIn").count == 0 {
          willChangeValue(forKey: "tags", withSetMutation: .minus, using: [tag])
          managedObjectContext.delete(tag)
          didChangeValue(forKey: "tags", withSetMutation: .minus, using: [tag])
        }
      }


    func updateSubviewConstraints()
      {
        tagViewArrangement = [[]]

        var row = 0, column = 0

        // Iterate over the tags
        for tag in tags.sorted(by: sortingBlock) {

          // Get the subview associated with the tag
          let tagView = tagViewDictionary[tag]!

          // Deactivate the old constraints
          if let left = tagView.leftConstraint, let top = tagView.topConstraint {
            NSLayoutConstraint.deactivate([left, top])
          }

          // If there isn't enough space in the current column, move to the next
          if tagView.width > availableWidthInRow(row) {
            tagViewArrangement.append([])
            row += 1
            column = 0
          }

          // Note the arrangement of the view
          tagViewArrangement[row].append(tagView)

          // Configure the constraint for the top of the view
          if row == 0 {
            tagView.topConstraint = tagView.topAnchor.constraint(equalTo: tagsView.topAnchor, constant: tagViewSpacing)
          }
          else {
            tagView.topConstraint = tagView.topAnchor.constraint(equalTo: tagViewArrangement[row - 1][column].bottomAnchor, constant: tagViewSpacing)
          }

          // Configure the constraint for the left of the view
          if column == 0 {
            tagView.leftConstraint = tagView.leftAnchor.constraint(equalTo: tagsView.leftAnchor, constant: tagViewSpacing)
          }
          else {
            tagView.leftConstraint = tagView.leftAnchor.constraint(equalTo: tagViewArrangement[row][column - 1].rightAnchor, constant: tagViewSpacing)
          }

          // Activate the new constraints
          NSLayoutConstraint.activate([tagView.leftConstraint!, tagView.topConstraint!])

          column += 1
        }
      }


    func availableWidthInRow(_ row: Int) -> CGFloat
      {
        var availableWidth = tagsView.frame.width - tagViewSpacing

        for view in tagViewArrangement[row] {
          availableWidth -= (view.width + tagViewSpacing)
        }

        return availableWidth
      }


    // MARK: - UIViewController

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    override func loadView()
      {
        // Configure the root view
        view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        // Configure the tags label
        titleLabel = UILabel(frame: .zero)
        titleLabel.text = NSLocalizedString("TAGS", comment: "")
        titleLabel.font = UIFont(name: "Helvetica", size: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Configure the tags view
        tagsView = UIView(frame: .zero)
        tagsView.layer.cornerRadius = 5.0
        tagsView.layer.borderWidth = 0.5
        tagsView.layer.borderColor = UIColor.lightGray.cgColor
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tagsView)

        // Configure the tag text field
        tagTextField = UITextField(frame: CGRect.zero)
        tagTextField.font = UIFont(name: "Helvetica", size: 18)
        tagTextField.borderStyle = .roundedRect
        tagTextField.placeholder = NSLocalizedString("TAG NAME", comment: "")
        tagTextField.textAlignment = .center
        tagTextField.returnKeyType = .done
        tagTextField.clearButtonMode = .always
        tagTextField.translatesAutoresizingMaskIntoConstraints = false
        tagTextField.delegate = self
        view.addSubview(tagTextField)

        // Configure the layout bindings for the title label
        titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30.0).isActive = true

        // Configure the layout bindings for the tags view
        tagsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tagsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tagsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0).isActive = true
        tagsView.bottomAnchor.constraint(equalTo: tagTextField.topAnchor, constant: -8.0).isActive = true

        // Configure the layout bindings for the tag text field
        tagTextField.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tagTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tagTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tagTextField.heightAnchor.constraint(equalToConstant: 40.0).isActive = true

        // Build the tag subview dictionary
        for tag in tags {
          let tagView = TagView(tag: tag, editing: isEditing, controller: self)
          tagViewDictionary[tag] = tagView
          tagsView.addSubview(tagView)
        }
      }


    override func viewWillAppear(_ animated: Bool)
      {
        super.viewWillAppear(animated)

        // Register custom observations
        observations = [
          Observation(source: self, keypaths: ["editing"], options: .initial, block:
              { (changes: [NSKeyValueChangeKey : Any]?) -> Void in

                // Show/hide the tagTextField
                self.tagTextField.isHidden = self.isEditing ? false : true

                // Set the editing states of the various tagViews
                for (_, tagView) in self.tagViewDictionary {
                  tagView.setEditing(self.isEditing)
                }
              }),
        ]
      }


    override func viewWillDisappear(_ animated: Bool)
      {
        super.viewWillDisappear(animated)

        // De-register custom observations
        observations.removeAll()
      }



    override func viewDidLayoutSubviews()
      {
        super.viewDidLayoutSubviews()

        updateSubviewConstraints()
      }


    override func setEditing(_ editing: Bool, animated: Bool)
      {
        // Enable key-value observation for the editing property
        willChangeValue(forKey: "editing")
        super.setEditing(editing, animated: animated)
        didChangeValue(forKey: "editing")
      }


    // MARK: - UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
      {
        // Call the parent RecipeViewController's implementation
        return recipeViewController.textFieldShouldBeginEditing(textField)
      }


    func textFieldShouldReturn(_ textField: UITextField) -> Bool
      {
        textField.resignFirstResponder()
        return true
      }


    func textFieldDidEndEditing(_ textField: UITextField)
      {
        // As long as we have a non-empty string, add a tag
        if let text = textField.text, text != "" {
          addTagWithName(text)
          textField.text = ""
        }

        // Call the parent RecipeViewController's implementation
        recipeViewController.textFieldDidEndEditing(textField)
      }

  }

/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class TagsViewController: UIViewController
  {

    var titleLabel: UILabel!
    var tagsView: UIView!

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

        // Configure the layout bindings for the title label
        titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 30.0).isActive = true

        // Configure the layout bindings for the tags view
        tagsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tagsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tagsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0).isActive = true
        tagsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Build the tag subview dictionary
        for tag in tags {
          let tagView = TagView(tag: tag, editing: isEditing, controller: self)
          tagViewDictionary[tag] = tagView
          tagsView.addSubview(tagView)
        }
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        setEditing(isEditing, animated: true)
      }


    override func viewDidLayoutSubviews()
      {
        super.viewDidLayoutSubviews()

        updateSubviewConstraints()
      }


    override func setEditing(_ editing: Bool, animated: Bool)
      {
        super.setEditing(editing, animated: animated)

        for (_, tagView) in tagViewDictionary {
          tagView.setEditing(editing)
        }
      }


    // MARK: - TagView

    class TagView: UIView
      {

        var recipeTag: Tag
        weak var tagsViewController: TagsViewController?

        var leftConstraint: NSLayoutConstraint?
        var topConstraint: NSLayoutConstraint?

        var nameLabelLeftConstraint: NSLayoutConstraint!
        var nameLabelRightConstraint: NSLayoutConstraint!
        var nameLabelWidthConstraint: NSLayoutConstraint!
        var nameLabelCenterXConstraint: NSLayoutConstraint!

        var nameLabel: UILabel!
        var deleteButton: UIButton!

        var width: CGFloat
          { return nameLabel.intrinsicContentSize.width + nameLabel.intrinsicContentSize.height + (2 * spacing) }

        let spacing: CGFloat = 2.5

        init(tag: Tag, editing: Bool, controller: TagsViewController)
          {
            self.recipeTag = tag
            self.tagsViewController = controller

            super.init(frame: CGRect.zero)
            layer.cornerRadius = 5.0
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.lightGray.cgColor
            translatesAutoresizingMaskIntoConstraints = false

            nameLabel = UILabel(frame: CGRect.zero)
            nameLabel.text = tag.name
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(nameLabel)

            deleteButton = button(self, action: #selector(TagView.deleteTag(_:)), controlEvents: .touchUpInside, imageName: "deleteImage")
            addSubview(deleteButton)

            // Establish layout constraints
            nameLabelLeftConstraint = nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: spacing)
            nameLabelRightConstraint = nameLabel.rightAnchor.constraint(equalTo: deleteButton.leftAnchor, constant: -spacing)

            nameLabelWidthConstraint = nameLabel.widthAnchor.constraint(equalToConstant: nameLabel.intrinsicContentSize.width)
            nameLabelCenterXConstraint = nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor)

            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

            deleteButton.widthAnchor.constraint(equalToConstant: nameLabel.intrinsicContentSize.height).isActive = true
            deleteButton.heightAnchor.constraint(equalToConstant: nameLabel.intrinsicContentSize.height).isActive = true
            deleteButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

            widthAnchor.constraint(equalToConstant: width).isActive = true
            heightAnchor.constraint(equalTo: nameLabel.heightAnchor).isActive = true

            setEditing(editing)
          }


        required init?(coder aDecoder: NSCoder)
          {
            fatalError("init(coder:) has not been implemented")
          }


        func setEditing(_ editing: Bool)
          {
            deleteButton.isHidden = editing ? false : true

            NSLayoutConstraint.deactivate(editing ? [nameLabelWidthConstraint, nameLabelCenterXConstraint] : [nameLabelLeftConstraint, nameLabelRightConstraint])
            NSLayoutConstraint.activate(editing ? [nameLabelLeftConstraint, nameLabelRightConstraint] : [nameLabelWidthConstraint, nameLabelCenterXConstraint])
          }


        func deleteTag(_ sender: UIButton)
          {
            tagsViewController!.removeTag(recipeTag)
          }

      }

  }

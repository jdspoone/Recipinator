/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


class TagsViewController: UIViewController
  {

    var tags: Set<Tag>
    var managedObjectContext: NSManagedObjectContext

    var tagViewDictionary: [Tag: TagView] = [:]
    var tagViewArrangement: [[TagView]] = [[]]

    let sortingBlock: (Tag, Tag) -> Bool =
        { (a: Tag, b: Tag) -> Bool in
          return a.name < b.name
        }

    let tagViewSpacing: CGFloat = 5.0

    init(tags: Set<Tag>, context: NSManagedObjectContext)
      {
        self.tags = tags
        self.managedObjectContext = context

        super.init(nibName: nil, bundle: nil)
      }


    func shouldCreateTagWithName(name: String) -> Bool
      {
        let request = NSFetchRequest(entityName: "Tag")
        request.predicate = NSPredicate(format: "name = %@", name)

        var results: [Tag] = []
        do { results = try managedObjectContext.executeFetchRequest(request) as! [Tag] }
        catch let e { fatalError("error: \(e)") }

        if results.count == 0 {
          return true
        }
        else {
          assert(results.count == 1, "unexpected state - multiple tags with name: \(name)")
          return false
        }
      }


    func addTagWithName(name: String)
      {
        // Get a tag object for the given name
        let tag = Tag.withName(name, inContext: managedObjectContext)

        // Add the tag to the set of tags, if it is not already in there
        if (tags.contains(tag) == false) {
          willChangeValueForKey("tags", withSetMutation: .UnionSetMutation, usingObjects: [tag])
          tags.insert(tag)
          didChangeValueForKey("tags", withSetMutation: .UnionSetMutation, usingObjects: [tag])

          let tagView = TagView(tag: tag, editing: editing, controller: self)
          view.addSubview(tagView)

          tagViewDictionary[tag] = tagView

          updateSubviewConstraints()
        }
      }


    func removeTag(tag: Tag)
      {
        // Delete the specified tag
        tags.remove(tag)

        willChangeValueForKey("tags", withSetMutation: .MinusSetMutation, usingObjects: [tag])
        managedObjectContext.deleteObject(tag)
        didChangeValueForKey("tags", withSetMutation: .MinusSetMutation, usingObjects: [tag])

        tagViewDictionary[tag]!.removeFromSuperview()

        updateSubviewConstraints()
      }


    func updateSubviewConstraints()
      {
        tagViewArrangement = [[]]

        var row = 0, column = 0

        // Iterate over the tags
        for tag in tags.sort(sortingBlock) {

          // Get the subview associated with the tag
          let tagView = tagViewDictionary[tag]!

          // Deactivate the old constraints
          if let left = tagView.leftConstraint, top = tagView.topConstraint {
            NSLayoutConstraint.deactivateConstraints([left, top])
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
            tagView.topConstraint = tagView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: tagViewSpacing)
          }
          else {
            tagView.topConstraint = tagView.topAnchor.constraintEqualToAnchor(tagViewArrangement[row - 1][column].bottomAnchor, constant: tagViewSpacing)
          }

          // Configure the constraint for the left of the view
          if column == 0 {
            tagView.leftConstraint = tagView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: tagViewSpacing)
          }
          else {
            tagView.leftConstraint = tagView.leftAnchor.constraintEqualToAnchor(tagViewArrangement[row][column - 1].rightAnchor, constant: tagViewSpacing)
          }

          // Activate the new constraints
          NSLayoutConstraint.activateConstraints([tagView.leftConstraint!, tagView.topConstraint!])

          column += 1
        }
      }


    func availableWidthInRow(row: Int) -> CGFloat
      {
        var availableWidth = view.frame.width - tagViewSpacing

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
        view = UIView(frame: CGRect.zero)
        view.layer.cornerRadius = 5.0
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGrayColor().CGColor
        view.translatesAutoresizingMaskIntoConstraints = false

        // Build the tag subview dictionary
        for tag in tags {
          let tagView = TagView(tag: tag, editing: editing, controller: self)
          tagViewDictionary[tag] = tagView
          view.addSubview(tagView)
        }
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        setEditing(editing, animated: true)
      }


    override func viewWillLayoutSubviews()
      {
        super.viewWillLayoutSubviews()

        updateSubviewConstraints()
      }


    override func setEditing(editing: Bool, animated: Bool)
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
          { return nameLabel.intrinsicContentSize().width + nameLabel.intrinsicContentSize().height + (2 * spacing) }

        let spacing: CGFloat = 2.5

        init(tag: Tag, editing: Bool, controller: TagsViewController)
          {
            self.recipeTag = tag
            self.tagsViewController = controller

            super.init(frame: CGRect.zero)
            layer.cornerRadius = 5.0
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.lightGrayColor().CGColor
            translatesAutoresizingMaskIntoConstraints = false

            nameLabel = UILabel(frame: CGRect.zero)
            nameLabel.text = tag.name
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(nameLabel)

            deleteButton = button(self, action: #selector(TagView.deleteTag(_:)), controlEvents: .TouchUpInside, imageName: "deleteImage")
            addSubview(deleteButton)

            // Establish layout constraints
            nameLabelLeftConstraint = nameLabel.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: spacing)
            nameLabelRightConstraint = nameLabel.rightAnchor.constraintEqualToAnchor(deleteButton.leftAnchor, constant: -spacing)

            nameLabelWidthConstraint = nameLabel.widthAnchor.constraintEqualToConstant(nameLabel.intrinsicContentSize().width)
            nameLabelCenterXConstraint = nameLabel.centerXAnchor.constraintEqualToAnchor(centerXAnchor)

            nameLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true

            deleteButton.widthAnchor.constraintEqualToConstant(nameLabel.intrinsicContentSize().height).active = true
            deleteButton.heightAnchor.constraintEqualToConstant(nameLabel.intrinsicContentSize().height).active = true
            deleteButton.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
            deleteButton.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true

            widthAnchor.constraintEqualToConstant(width).active = true
            heightAnchor.constraintEqualToAnchor(nameLabel.heightAnchor).active = true

            setEditing(editing)
          }


        required init?(coder aDecoder: NSCoder)
          {
            fatalError("init(coder:) has not been implemented")
          }


        func setEditing(editing: Bool)
          {
            deleteButton.hidden = editing ? false : true

            NSLayoutConstraint.deactivateConstraints(editing ? [nameLabelWidthConstraint, nameLabelCenterXConstraint] : [nameLabelLeftConstraint, nameLabelRightConstraint])
            NSLayoutConstraint.activateConstraints(editing ? [nameLabelLeftConstraint, nameLabelRightConstraint] : [nameLabelWidthConstraint, nameLabelCenterXConstraint])
          }


        func deleteTag(sender: UIButton)
          {
            tagsViewController!.removeTag(recipeTag)
          }

      }

  }
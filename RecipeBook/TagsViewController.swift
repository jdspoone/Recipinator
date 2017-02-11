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
        if (tags.contains(tag) == false) {
          willChangeValue(forKey: "tags", withSetMutation: .union, using: [tag])
          tags.insert(tag)
          didChangeValue(forKey: "tags", withSetMutation: .union, using: [tag])

          let tagView = TagView(tag: tag, editing: isEditing, controller: self)
          view.addSubview(tagView)

          tagViewDictionary[tag] = tagView

          updateSubviewConstraints()
        }
      }


    func removeTag(_ tag: Tag)
      {
        // Delete the specified tag
        tags.remove(tag)

        willChangeValue(forKey: "tags", withSetMutation: .minus, using: [tag])
        managedObjectContext.delete(tag)
        didChangeValue(forKey: "tags", withSetMutation: .minus, using: [tag])

        tagViewDictionary[tag]!.removeFromSuperview()

        updateSubviewConstraints()
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
            tagView.topConstraint = tagView.topAnchor.constraint(equalTo: view.topAnchor, constant: tagViewSpacing)
          }
          else {
            tagView.topConstraint = tagView.topAnchor.constraint(equalTo: tagViewArrangement[row - 1][column].bottomAnchor, constant: tagViewSpacing)
          }

          // Configure the constraint for the left of the view
          if column == 0 {
            tagView.leftConstraint = tagView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: tagViewSpacing)
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
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false

        // Build the tag subview dictionary
        for tag in tags {
          let tagView = TagView(tag: tag, editing: isEditing, controller: self)
          tagViewDictionary[tag] = tagView
          view.addSubview(tagView)
        }
      }


    override func viewDidLoad()
      {
        super.viewDidLoad()

        setEditing(isEditing, animated: true)
      }


    override func viewWillLayoutSubviews()
      {
        super.viewWillLayoutSubviews()

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

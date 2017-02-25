/*

  Written by Jeff Spooner

*/

import UIKit


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


    func deleteTag(_ sender: AnyObject?)
      {
        tagsViewController!.removeTag(recipeTag)
      }

  }

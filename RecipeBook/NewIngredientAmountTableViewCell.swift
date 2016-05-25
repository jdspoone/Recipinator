/*

  Written by Jeff Spooner

*/

import UIKit


class NewIngredientAmountTableViewCell: UITableViewCell, UITextFieldDelegate
  {
    weak var parentTableView: UITableView?

    var nameTextField: UITextField!
    var amountTextField: UITextField!

    var recipeViewController: RecipeViewController
      {
        return parentTableView!.delegate as! RecipeViewController
      }


    init(tableView: UITableView)
      {
        self.parentTableView = tableView

        super.init(style: .Default, reuseIdentifier: "newIngredientTableViewCell")

        nameTextField = UITextField(frame: CGRect.zero)
        nameTextField.placeholder = "Name"
        nameTextField.returnKeyType = .Done
        nameTextField.delegate = self
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        amountTextField = UITextField(frame: CGRect.zero)
        amountTextField.placeholder = "Amount"
        amountTextField.textAlignment = .Right
        amountTextField.returnKeyType = .Done
        amountTextField.delegate = self
        amountTextField.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(nameTextField)
        contentView.addSubview(amountTextField)

        let leftIndentation: CGFloat = 16.0
        let rightIndentation: CGFloat = 8.0

        nameTextField.widthAnchor.constraintEqualToAnchor(amountTextField.widthAnchor).active = true

        nameTextField.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: leftIndentation).active = true
        nameTextField.rightAnchor.constraintEqualToAnchor(amountTextField.leftAnchor).active = true
        nameTextField.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        nameTextField.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true

        amountTextField.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -rightIndentation).active = true
        amountTextField.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
        amountTextField.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
      }


    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
      {
        return recipeViewController.editing
      }


    func textFieldDidBeginEditing(textField: UITextField)
      {
        recipeViewController.activeSubview = textField
      }


    func textFieldShouldReturn(textField: UITextField) -> Bool
      {
        // Allow users to end editting if both the name and amount text fields are empty
        if ((nameTextField.text == nil || nameTextField.text == "") && (amountTextField.text == nil || amountTextField.text == "")) {
          // Forcibly end editting of the textField
          textField.endEditing(true)

          // Set the RecipeViewController's newIngredientAmount flag to be false, and tell the parentTable to reload it's data
          recipeViewController.newIngredientAmount = false
          parentTableView!.reloadData()

          return true
        }
        // Allow users to end editting if the name text field is non-empty
        else if (nameTextField.text != nil || nameTextField.text != "") {
          textField.endEditing(true)
          return true
        }
        // Otherwise prevent ending editting
        else {
          return false
        }
      }


    func textFieldDidEndEditing(textField: UITextField)
      {
        recipeViewController.activeSubview = nil
      }

  }
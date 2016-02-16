/*

  Written by Jeff Spooner

*/

import UIKit


class IngredientsTableViewCell: UITableViewCell, UITextFieldDelegate
  {
    weak var parentTableView: UITableView?

    var ingredientAmount: IngredientAmount

    var nameTextField: UITextField!
    var amountTextField: UITextField!

    var recipeViewController: RecipeViewController
      {
        return parentTableView!.delegate as! RecipeViewController
      }


    init(ingredientAmount: IngredientAmount, tableView: UITableView)
      {
        self.ingredientAmount = ingredientAmount
        self.parentTableView = tableView

        super.init(style: .Default, reuseIdentifier: "ingredientTableViewCell")

        nameTextField = UITextField(frame: CGRect.zero)
        nameTextField.placeholder = "Name"
        nameTextField.text = ingredientAmount.ingredient.name
        nameTextField.returnKeyType = .Done
        nameTextField.delegate = self
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        amountTextField = UITextField(frame: CGRect.zero)
        amountTextField.placeholder = "Amount"
        amountTextField.text = ingredientAmount.amount
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
        if textField.text != nil && textField.text != "" {
          textField.endEditing(true)
          return true
        }
        return false
      }


    func textFieldDidEndEditing(textField: UITextField)
      {
        switch textField {
          case nameTextField :
            ingredientAmount.ingredient.name = textField.text!
          case amountTextField :
            ingredientAmount.amount = textField.text!
          default :
            print("")
        }
        recipeViewController.activeSubview = nil
      }

  }

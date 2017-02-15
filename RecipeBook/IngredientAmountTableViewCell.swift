/*

  Written by Jeff Spooner

*/

import UIKit


class IngredientAmountTableViewCell: UITableViewCell, UITextFieldDelegate
  {
    weak var parentTableView: UITableView?

    var ingredientAmount: IngredientAmount

    var nameTextField: UITextField!
    var amountTextField: UITextField!

    var recipeViewController: RecipeViewController
      {
        return parentTableView!.delegate as! RecipeViewController
      }


    init(parentTableView: UITableView, ingredientAmount: IngredientAmount)
      {
        self.parentTableView = parentTableView
        self.ingredientAmount = ingredientAmount

        super.init(style: .default, reuseIdentifier: "ingredientTableViewCell")

        nameTextField = UITextField(frame: CGRect.zero)
        nameTextField.font = UIFont(name: "Helvetica", size: 16)
        nameTextField.placeholder = NSLocalizedString("NAME", comment: "")
        nameTextField.text = ingredientAmount.ingredient.name
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        amountTextField = UITextField(frame: CGRect.zero)
        amountTextField.font = UIFont(name: "Helvetica", size: 16)
        amountTextField.placeholder = NSLocalizedString("AMOUNT", comment: "")
        amountTextField.text = ingredientAmount.amount
        amountTextField.textAlignment = .right
        amountTextField.returnKeyType = .done
        amountTextField.delegate = self
        amountTextField.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(nameTextField)
        contentView.addSubview(amountTextField)

        let leftIndentation: CGFloat = 16.0
        let rightIndentation: CGFloat = 8.0

        nameTextField.widthAnchor.constraint(equalTo: amountTextField.widthAnchor).isActive = true

        nameTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: leftIndentation).isActive = true
        nameTextField.rightAnchor.constraint(equalTo: amountTextField.leftAnchor).isActive = true
        nameTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        nameTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        amountTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -rightIndentation).isActive = true
        amountTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        amountTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
      }

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }


    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
      {
        return recipeViewController.isEditing
      }


    func textFieldDidBeginEditing(_ textField: UITextField)
      {
        recipeViewController.activeSubview = textField
      }


    func textFieldShouldReturn(_ textField: UITextField) -> Bool
      {
        // Allow the user to end editing if the name text field is non-empty
        if nameTextField.text != nil && nameTextField.text != "" {
          textField.endEditing(true)
          return true
        }
        return false
      }


    func textFieldDidEndEditing(_ textField: UITextField)
      {
        // Switch on the textField
        switch textField {

          // If the nameTextField's text differs from the ingredientAmount's ingredient name, update the ingredient amount
          case nameTextField :
            if textField.text! != ingredientAmount.ingredient.name {
              ingredientAmount.updateIngredient(textField.text!, context: recipeViewController.managedObjectContext)
            }

          // Update the ingredientAmount's amount
          case amountTextField :
            ingredientAmount.amount = textField.text!

          default :
            fatalError("unexpected case")
        }

        // Set the parent RecipeViewController's activeSubview to nil if we are still the active subview
        if recipeViewController.activeSubview === textField {
          recipeViewController.activeSubview = nil
        }
      }

  }

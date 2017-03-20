/*

  Written by Jeff Spooner

*/

import UIKit


class IngredientAmountTableViewCell: UITableViewCell
  {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
      {
        // Override to use value1 style
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
      }


    // MARK: - UITableViewCell

    required init?(coder aDecoder: NSCoder)
      {
        fatalError("init(coder:) has not been implemented")
      }

  }

/*

  Written by Jeff Spooenr

*/

import UIKit


func roundedSquareButton(_ target: AnyObject?, action: Selector, controlEvents: UIControlEvents, imageName: String) -> UIButton
  {
    let button = UIButton(type: .custom)
    button.addTarget(target, action: action, for: controlEvents)
    button.setImage(UIImage(named: imageName), for: UIControlState())
    button.layer.cornerRadius = 5.0
    button.layer.borderWidth = 0.5
    button.layer.borderColor = UIColor.lightGray.cgColor
    button.showsTouchWhenHighlighted = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }


func button(_ target: AnyObject?, action: Selector, controlEvents: UIControlEvents, imageName: String) -> UIButton
  {
    let button = UIButton(type: .custom)
    button.addTarget(target, action: action, for: controlEvents)
    button.setImage(UIImage(named: imageName), for: UIControlState())
    button.showsTouchWhenHighlighted = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

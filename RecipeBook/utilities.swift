/*

  Written by Jeff Spooenr

*/

import UIKit


func roundedSquareButton(target: AnyObject?, action: Selector, controlEvents: UIControlEvents, imageName: String) -> UIButton
  {
    let button = UIButton(type: .Custom)
    button.addTarget(target, action: action, forControlEvents: controlEvents)
    button.setBackgroundImage(UIImage(named: imageName), forState: .Normal)
    button.layer.cornerRadius = 5.0
    button.layer.borderWidth = 0.5
    button.layer.borderColor = UIColor.lightGrayColor().CGColor
    button.showsTouchWhenHighlighted = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }


func button(target: AnyObject?, action: Selector, controlEvents: UIControlEvents, imageName: String) -> UIButton
  {
    let button = UIButton(type: .Custom)
    button.addTarget(target, action: action, forControlEvents: controlEvents)
    button.setBackgroundImage(UIImage(named: imageName), forState: .Normal)
    button.showsTouchWhenHighlighted = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }
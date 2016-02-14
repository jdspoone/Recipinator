/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


@objc(Recipe)
class Recipe: BaseObject
  {

    @NSManaged var name: String
    @NSManaged var imageData: NSData?
    @NSManaged var ingredientAmounts: Set<IngredientAmount>
    @NSManaged var steps: Set<Step>
    @NSManaged var tags: Set<Tag>

    var image: UIImage?
      {
        get { return imageData != nil ? UIImage(data: imageData!) : nil }
        set { imageData = newValue != nil ? UIImageJPEGRepresentation(newValue!, 1.0) : nil }
      }


    init(name: String, imageData: NSData?, ingredientAmounts: Set<IngredientAmount>, steps: Set<Step>, tags: Set<Tag>, context: NSManagedObjectContext)
      {
        super.init(name: "Recipe", context: context)

        self.name = name
        self.imageData = imageData
        self.ingredientAmounts = ingredientAmounts
        self.steps = steps
        self.tags = tags
      }


    override class func properties() -> [String : Property]
      {
        return [
          "name" : .Attribute,
          "imageData" : .Attribute,
          "ingredientAmounts" : .ToMany(IngredientAmount),
          "steps" : .ToMany(Step)
        ]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
      }

  }

/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


@objc(Recipe)
class Recipe: BaseObject
  {

    @NSManaged var name: String
    @NSManaged var imageData: Data?
    @NSManaged var ingredientAmounts: Set<IngredientAmount>
    @NSManaged var steps: Set<Step>
    @NSManaged var tags: Set<Tag>

    var image: UIImage?
      {
        get { return imageData != nil ? UIImage(data: imageData!) : nil }
        set { imageData = newValue != nil ? UIImageJPEGRepresentation(newValue!, 1.0) : nil }
      }


    init(name: String, imageData: Data?, ingredientAmounts: Set<IngredientAmount>, steps: Set<Step>, tags: Set<Tag>, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Recipe", context: context, insert: insert)

        self.name = name
        self.imageData = imageData
        self.ingredientAmounts = ingredientAmounts
        self.steps = steps
        self.tags = tags
      }


    override class func properties() -> [String : Property]
      {
        return [
          "name" : .attribute,
          "imageData" : .attribute,
          "ingredientAmounts" : .toMany(IngredientAmount.self),
          "steps" : .toMany(Step.self)
        ]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

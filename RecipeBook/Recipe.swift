/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


@objc(Recipe)
class Recipe: BaseObject
  {

    @NSManaged var name: String
    @NSManaged var images: Set<Image>
    @NSManaged var ingredientAmounts: Set<IngredientAmount>
    @NSManaged var steps: Set<Step>
    @NSManaged var tags: Set<Tag>

    init(name: String, images: Set<Image>, ingredientAmounts: Set<IngredientAmount>, steps: Set<Step>, tags: Set<Tag>, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Recipe", context: context, insert: insert)

        self.name = name
        self.images = images
        self.ingredientAmounts = ingredientAmounts
        self.steps = steps
        self.tags = tags
      }


    override class func properties() -> [String : Property]
      {
        return [
          "name" : .attribute,
          "images" : .toMany(Image.self),
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

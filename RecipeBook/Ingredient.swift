/*

  Written by Jeff Spooner

*/

import Foundation
import CoreData


@objc(Ingredient)
class Ingredient : BaseObject
  {

    @NSManaged var name: String


    init(name: String, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Ingredient", context: context, insert: insert)

        self.name = name
      }


    override class func properties() -> [String : Property]
      {
        return [
          "name" : .Attribute
        ]
      }


    // MARK: NSManagedObject

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
      }

  }


// MARK: -

@objc(IngredientAmount)
class IngredientAmount : BaseObject
  {

    @NSManaged var ingredient: Ingredient
    @NSManaged var amount: String
    @NSManaged var number: Int16

    init(ingredient: Ingredient, amount: String, number: Int16, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "IngredientAmount", context: context, insert: insert)

        self.ingredient = ingredient
        self.amount = amount
        self.number = number
      }


    override class func properties() -> [String : Property]
      {
        return [
          "ingredient" : .ToOne(Ingredient),
          "amount" : .Attribute
        ]
      }


    // MARK: NSManagedObject

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
      }

  }
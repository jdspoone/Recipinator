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


    func updateIngredient(name: String, context: NSManagedObjectContext)
      {
        assert(name != "", "unexpected state - the empty string is not a valid ingredient name")

        // Look for an already existing ingredient with the same name
        let request = NSFetchRequest(entityName: "Ingredient")
        request.predicate = NSPredicate(format: "name = %@", name)

        var results: [Ingredient] = []
        do { results = try context.executeFetchRequest(request) as! [Ingredient] }
        catch let e { fatalError("error: \(e)") }

        if results.count == 0 {
          ingredient.name = name
        }
        else {
          assert(results.count == 1, "unexpected state - \(results.count) ingredients with name: \(name)")

          if inserted == false {
            context.insertObject(self)
          }

          ingredient = results.first!
        }
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
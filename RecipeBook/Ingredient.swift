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


    class func withName(_ name: String, inContext context: NSManagedObjectContext) -> Ingredient
      {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Ingredient")
        request.predicate = NSPredicate(format: "name = %@", name)

        // Query the context for any ingredients with the given name
        var results: [Ingredient] = []
        do { results = try context.fetch(request) as! [Ingredient] }
        catch let e { fatalError("errorL \(e)") }

        // If there are no ingredients with that name, return
        if results.count == 0 {
          return Ingredient(name: name, context: context)
        }
        else {
          assert(results.count == 1, "unexpected state - \(results.count) ingredients with name: \(name)")
          return results.first!
        }
      }


    // MARK: BaseObject

    override class func properties() -> [String : Property]
      {
        return [
          "name" : .attribute
        ]
      }


    // MARK: NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
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


    func updateIngredient(_ name: String, context: NSManagedObjectContext)
      {
        assert(name != "", "unexpected state - the empty string is not a valid ingredient name")

        // Look for an already existing ingredient with the same name
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Ingredient")
        request.predicate = NSPredicate(format: "name = %@", name)

        var results: [Ingredient] = []
        do { results = try context.fetch(request) as! [Ingredient] }
        catch let e { fatalError("error: \(e)") }

        if results.count == 0 {
          ingredient.name = name
        }
        else {
          assert(results.count == 1, "unexpected state - \(results.count) ingredients with name: \(name)")

          if isInserted == false {
            context.insert(self)
          }

          ingredient = results.first!
        }
      }


    override class func properties() -> [String : Property]
      {
        return [
          "ingredient" : .toOne(Ingredient.self),
          "amount" : .attribute
        ]
      }


    // MARK: NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

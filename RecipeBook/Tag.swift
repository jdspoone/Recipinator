/*

  Written by Jeff Spooner

*/

import Foundation
import CoreData


@objc(Tag)
class Tag: BaseObject
  {
  
    @NSManaged var name: String


    init(name: String, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Tag", context: context, insert: insert)

        self.name = name
      }


    class func withName(_ name: String, inContext context: NSManagedObjectContext) -> Tag
      {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        request.predicate = NSPredicate(format: "name = %@", name)

        // Query the context for any ingredients with the given name
        var results: [Tag] = []
        do { results = try context.fetch(request) as! [Tag] }
        catch let e { fatalError("errorL \(e)") }

        // If there are no ingredients with that name, return
        if results.count == 0 {
          return Tag(name: name, context: context)
        }
        else {
          assert(results.count == 1, "unexpected state - multiple tags with name: \(name)")
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

      
    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

/*

  Written by Jeff Spooner

*/

import Foundation
import CoreData


@objc(Tag)
class Tag: BaseObject
  {
  
    @NSManaged var name: String


    init(name: String, context: NSManagedObjectContext)
      {
        super.init(name: "Tag", context: context)

        self.name = name
      }


    override class func properties() -> [String : Property]
      {
        return [
            "name" : .Attribute
          ]
      }

      
    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
      }

  }

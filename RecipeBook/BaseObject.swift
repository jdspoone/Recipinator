/*

  Written by Jeff Spooner

*/

import CoreData


@objc(BaseObject)
class BaseObject: NSManagedObject
  {

    enum Property
      {
        case attribute
        case toOne(BaseObject.Type)
        case toMany(BaseObject.Type)
      }


    init(name: String, context: NSManagedObjectContext, insert: Bool, referenceObject obj: BaseObject? = nil)
      {
        let entityDescription = NSEntityDescription.entity(forEntityName: name, in: context)!

        super.init(entity: entityDescription, insertInto: insert ? context : nil)
      }


    class func properties() -> [String : Property]
      {
        return [:]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

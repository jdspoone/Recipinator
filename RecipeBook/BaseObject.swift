/*

  Written by Jeff Spooner

*/

import CoreData


@objc(BaseObject)
class BaseObject: NSManagedObject
  {

    enum Property
      {
        case Attribute
        case ToOne(BaseObject.Type)
        case ToMany(BaseObject.Type)
      }


    init(name: String, context: NSManagedObjectContext, referenceObject obj: BaseObject? = nil)
      {
        let entityDescription = NSEntityDescription.entityForName(name, inManagedObjectContext: context)!

        super.init(entity: entityDescription, insertIntoManagedObjectContext: context)
      }


    class func properties() -> [String : Property]
      {
        return [:]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
      }

  }

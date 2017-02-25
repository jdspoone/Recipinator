/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


@objc(Step)
class Step : BaseObject
  {

    @NSManaged var number: Int16
    @NSManaged var summary: String
    @NSManaged var detail: String
    @NSManaged var images: Set<Image>


    init(number: Int16, summary: String, detail: String, images: Set<Image>, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Step", context: context, insert: insert)

        self.number = number
        self.summary = summary
        self.detail = detail
        self.images = images
      }


    override class func properties() -> [String : Property]
      {
        return [
          "summary" : .attribute,
          "detail" : .attribute,
          "images" : .toMany(Image.self),
        ]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

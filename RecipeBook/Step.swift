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
    @NSManaged var imageData: Data?

    var image: UIImage?
      {
        get { return imageData != nil ? UIImage(data: imageData!) : nil }
        set { imageData = newValue != nil ? UIImageJPEGRepresentation(newValue!, 1.0) : nil }
      }


    init(number: Int16, summary: String, detail: String, imageData: Data?, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Step", context: context, insert: insert)

        self.number = number
        self.summary = summary
        self.detail = detail
        self.imageData = imageData
      }


    override class func properties() -> [String : Property]
      {
        return [
          "summary" : .attribute,
          "detail" : .attribute,
          "imageData" : .attribute
        ]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

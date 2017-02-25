/*

  Written by Jeff Spooner

*/

import UIKit
import CoreData


@objc(Image)
class Image : BaseObject
  {

    @NSManaged var imageData: Data?
    @NSManaged var index: Int16

    var image: UIImage?
      {
        get { return imageData != nil ? UIImage(data: imageData!) : nil }
        set { imageData = newValue != nil ? UIImageJPEGRepresentation(newValue!, 1.0) : nil }
      }


    init(imageData: Data?, index: Int16, context: NSManagedObjectContext, insert: Bool = true)
      {
        super.init(name: "Image", context: context, insert: insert)

        self.imageData = imageData
        self.index = index
      }


    override class func properties() -> [String : Property]
      {
        return [
          "imageData" : .attribute,
          "number" : .attribute
        ]
      }


    // MARK: - NSManagedObject

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      {
        super.init(entity: entity, insertInto: context)
      }

  }

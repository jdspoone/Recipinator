/*

  Written by Jeff Spooner

  Custom migration policy for Step instances

*/

import CoreData


class StepToStepPolicy: NSEntityMigrationPolicy
  {

    override func createDestinationInstances(forSource sourceInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws
      {
        // Get the user info dictionary
        let userInfo = mapping.userInfo!

        // Migrate to version 2
        if let sourceVersion = userInfo["sourceVersion"] as? String {

          // Get the source keys and values
          let sourceKeys = Array(sourceInstance.entity.attributesByName.keys)
          let sourceValues = sourceInstance.dictionaryWithValues(forKeys: sourceKeys)

          // Create the destination Recipe instance
          let destinationInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)

          // Get the destination keys
          let destinationKeys = Array(destinationInstance.entity.attributesByName.keys)

          // Set all those attributes of the destination instance which are the same as those of the source instance
          for key in destinationKeys {
            if let value = sourceValues[key] {
              destinationInstance.setValue(value, forKey: key)
            }
          }

          // Switch on the source version
          switch sourceVersion {

            case "v1.1":
              // Initialize an empty set
              var images = Set<NSManagedObject>()

              // If the source instance has associated image data
              if let imageData = sourceValues["imageData"] as? NSData {

                // Create a new image object
                let image = NSEntityDescription.insertNewObject(forEntityName: "Image", into: manager.destinationContext)

                // Set the attributes of the new image object
                image.setValue(0, forKey: "index")
                image.setValue(imageData, forKey: "imageData")

                // Set the relationships of the new image object
                image.setValue(destinationInstance, forKey: "stepUsedIn")

                // Add the new image to the set of images
                images.insert(image)
              }

              // Update the destination instance's image relationship
              destinationInstance.setValue(images, forKey: "images")

            default:
              break

          }

          // Associate the data between the source and destination instances
          manager.associate(sourceInstance: sourceInstance, withDestinationInstance: destinationInstance, for: mapping)
        }
        // Otherwise, defer to super's implementation
        else {
          try super.createDestinationInstances(forSource: sourceInstance, in: mapping, manager: manager)
        }

      }

  }

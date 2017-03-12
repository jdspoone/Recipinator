/*

  Written by Jeff Spooner

  Custom migration policy for IngredientAmount instances

*/

import CoreData


class IngredientAmountToIngredientAmountPolicy: NSEntityMigrationPolicy
  {

    override func createRelationships(forDestination destinationInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws
      {
        // Get the user info dictionary
        let userInfo = mapping.userInfo!

        // Get the source version
        let sourceVersion = userInfo["sourceVersion"] as? String

        // If a source version was specified
        if let sourceVersion = sourceVersion {

          // Get the source note
          let sourceIngredientAmount = manager.sourceInstances(forEntityMappingName: mapping.name, destinationInstances: [destinationInstance]).first!

          // Get the source note's relationship keys and values
          let sourceRelationshipKeys = Array(sourceIngredientAmount.entity.relationshipsByName.keys)
          let sourceRelationshipValues = sourceIngredientAmount.dictionaryWithValues(forKeys: sourceRelationshipKeys)

          // Switch on the source version
          switch sourceVersion {

            // Migrating from v1.2 to v1.3
            case "v1.2":

              // Get the source instance's incorrectly named recipesUsedIn relationship
              let sourceRecipe = sourceRelationshipValues["recipesUsedIn"] as! NSManagedObject

              // Get the corresponding destination recipe
              let destinationRecipe = manager.destinationInstances(forEntityMappingName: "RecipeToRecipe", sourceInstances: [sourceRecipe]).first!

              // Set the destination instance's recipeUsedIn relationship
              destinationInstance.setValue(destinationRecipe, forKey: "recipeUsedIn")

            default:
              break
          }

        }
      }

  }

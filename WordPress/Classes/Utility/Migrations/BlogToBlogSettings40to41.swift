import Foundation



/**
 *  @class      BlogToBlogSettings40to41
 *  @brief      This class should be executed during the migration from Data Model Mark 40 >> 41.
 *              It's main goal is to set the relationship between the *Blog* and *BlogSetting* instances,
 *              in the destination context.
 */
class BlogToBlogSettings40to41: NSEntityMigrationPolicy
{
    override func createRelationshipsForDestinationInstance(dBlogSettings: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        
        // 1. Load the Source Blog
        let sInstances = manager.sourceInstancesForEntityMappingNamed(mapping.name, destinationInstances: [dBlogSettings])
        assert(sInstances.count == 1)
        
        guard let sBlog = sInstances.first else {
            print("Migration Error: Couldn't load Source Blog Instance")
            return
        }
        
        // 2. Load the Destination Blog Instance
        let dInstances = manager.destinationInstancesForEntityMappingNamed("BlogToBlog", sourceInstances: [sBlog])
        assert(sInstances.count == 1)

        guard let dBlog = dInstances.first else {
            print("Migration Error: Couldn't load Destination Blog Instance")
            return
        }
        
        // 3. Set the BlogSetting <> Blog Relationship
        dBlogSettings.setValue(dBlog, forKey: "blog")
    }
}

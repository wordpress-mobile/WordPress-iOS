import Foundation



/**
 *  @class      BlogToBlogSettings40to41
 *  @brief      This class should be executed during the migration from Data Model Mark 40 >> 41.
 *              It's main goal is to set the relationship between the *Blog* and *BlogSetting* instances,
 *              in the destination context.
 */
class BlogToBlogSettings40to41: NSEntityMigrationPolicy
{
    override func createRelationshipsForDestinationInstance(blogSettings: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        
        // 1. Load the Source Blog
        let sInstances = manager.sourceInstancesForEntityMappingNamed(mapping.name, destinationInstances: [blogSettings])
        assert(sInstances.count == 1)
        
        guard let sBlog = sInstances.first else {
            print("Migration Error: Couldn't load Source Blog Instance")
            return
        }
        
        // 2. Load the Source Blog ID
        guard let blogID = sBlog.valueForKey("blogID") as? NSNumber else {
            print("Migration Error: Couldn't load blogID")
            return
        }
        
        // 3. Load the Destination Blog Instance
        guard let dBlog = blogWithBlogID(blogID, context: manager.destinationContext) else {
            print("Migration Error: Couldn't load Destination Blog Instance")
            return
        }
        
        // 4. Set the BlogSetting <> Blog Relationship
        blogSettings.setValue(dBlog, forKey: "blog")
    }
    

    // MARK: - Private Helpers
    private func blogWithBlogID(blogID : NSNumber, context: NSManagedObjectContext) -> NSManagedObject? {
        let request                 = NSFetchRequest(entityName: Blog.classNameWithoutNamespaces())
        request.predicate           = NSPredicate(format: "blogID == %@", blogID)
        request.includesSubentities = false

        do {
            return try context.executeFetchRequest(request).first as? NSManagedObject
        } catch {
            print("Migration Error: \(error)")
        }
        
        return nil
    }
}

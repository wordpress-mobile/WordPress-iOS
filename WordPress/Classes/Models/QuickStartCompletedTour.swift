@objc(QuickStartCompletedTour)
open class QuickStartCompletedTour: NSManagedObject {
    // Relations
    @NSManaged open var completedBlog: Blog?
    @NSManaged open var skippedBlog: Blog?

    // Properties
    @NSManaged open var tourID: String
}

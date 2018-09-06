@objc(QuickStartCompletedTour)
open class QuickStartCompletedTour: NSManagedObject {
    // Relations
    @NSManaged open var blog: Blog

    // Properties
    @NSManaged open var tourID: String
}

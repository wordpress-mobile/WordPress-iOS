@objc(QuickStartTourState)
open class QuickStartTourState: NSManagedObject {
    // Relations
    @NSManaged open var blog: Blog?
    @NSManaged open var completed: Bool
    @NSManaged open var skipped: Bool

    // Properties
    @NSManaged open var tourID: String
}

import Foundation

extension AbstractPost {

    /// The string to display to the user representing a post's date.
    ///
    /// - **Scheduled**: Displays time + date
    /// - **Immediately**: Displays "Publish Immediately" string
    /// - **Published or Draft**: Shows relative date when < 7 days
    public func displayDate() -> String? {
        let context = managedObjectContext ?? ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        let timeZone = blogService.timeZone(for: blog)

        if originalIsDraft() || status == .pending {
            return dateModified?.mediumString(timeZone: timeZone)
        } else if isScheduled() {
            return dateCreated?.mediumStringWithTime(timeZone: timeZone)
        } else if shouldPublishImmediately() {
            return NSLocalizedString("Publish Immediately", comment: "A short phrase indicating a post is due to be immedately published.")
        } else {
            return dateCreated?.mediumString(timeZone: timeZone)
        }
    }
}

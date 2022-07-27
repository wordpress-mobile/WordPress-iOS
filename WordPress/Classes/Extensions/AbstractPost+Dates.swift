import Foundation

extension AbstractPost {

    /// The string to display to the user representing a post's date.
    ///
    /// - **Scheduled**: Displays time + date
    /// - **Immediately**: Displays "Publish Immediately" string
    /// - **Published or Draft**: Shows relative date when < 7 days
    public func displayDate() -> String? {
        assert(self.managedObjectContext != nil)

        let timeZone = blog.timeZone

        // Unpublished post shows relative or date string
        if originalIsDraft() || status == .pending {
            return dateModified?.toMediumString(inTimeZone: timeZone)
        }

        // Scheduled Post shows date with time to be clear about when it goes live
        if isScheduled() {
            return dateCreated?.mediumStringWithTime(timeZone: timeZone)
        }

        // Publish Immediately shows hard coded string
        if shouldPublishImmediately() {
            return NSLocalizedString("Publish Immediately", comment: "A short phrase indicating a post is due to be immedately published.")
        }

        return dateCreated?.toMediumString(inTimeZone: timeZone)
    }
}

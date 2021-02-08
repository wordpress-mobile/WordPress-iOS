// Activity Log has some specific needs when it comes to formatting Dates, that pop up in few places.
// (at the minimum the Activity Log list, detail view, and the `ActivityStore`.
// This encapsulates those needs in one place.
struct ActivityDateFormatting {
    static func mediumDateFormatterWithTime(for site: JetpackSiteRef) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = timeZone(for: site)

        return formatter
    }

    static func longDateFormatter(for site: JetpackSiteRef,
                                  withTime: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = withTime ? .short : .none
        formatter.timeZone = timeZone(for: site)

        return formatter
    }

    static func timeZone(for site: JetpackSiteRef, managedObjectContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) -> TimeZone {
        let blogService = BlogService(managedObjectContext: managedObjectContext)

        guard let blog = blogService.blog(byBlogId: site.siteID as NSNumber) else {
            DDLogInfo("[ActivityDateFormatting] Couldn't find a blog with specified siteID. Falling back to UTC.")
            return TimeZone(secondsFromGMT: 0)!
        }

        return blogService.timeZone(for: blog)
    }
}

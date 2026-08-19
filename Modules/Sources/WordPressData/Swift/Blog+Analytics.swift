import Foundation
import CoreData
import WordPressShared

extension Blog: BlogAnalyticsRepresentable {
    /// A `Sendable` snapshot of the properties analytics attaches to an event.
    ///
    /// The read runs on the blog's own context queue, so the snapshot is safe to
    /// hand to the analytics layer from any thread. This matters because
    /// `dotComID`'s getter can mutate the object, and `isWPForTeams` faults the
    /// `options` relationship — neither is safe to touch off-queue.
    public var analyticsProperties: BlogAnalyticsProperties {
        guard let managedObjectContext else {
            return BlogAnalyticsProperties(dotComID: dotComID.map { Int($0.int64Value) }, isWPForTeams: isWPForTeams)
        }
        return managedObjectContext.performAndWait {
            BlogAnalyticsProperties(dotComID: dotComID.map { Int($0.int64Value) }, isWPForTeams: isWPForTeams)
        }
    }
}

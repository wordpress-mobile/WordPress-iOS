import Foundation

/// This is all based on Dennis Snell implementation on Calypso.
/// Keeping the same function and parameters names to be able to re use the documentation.
/// https://github.com/Automattic/wp-calypso/tree/master/client/state/activity-log/log/is-discarded
///
public class ActivityUtils {

    /// Returns a function which can be used to compute whether or not an event should be considered discarded.
    ///
    /// - Parameters:
    ///     - rewinds: The list of pairs of rewind event timestamps and associated backup event timestamps.
    ///     - viewFrom: Timestamp from perspective from which we are analyzing discardability of events.
    ///
    class func makeIsDiscarded(rewinds: [(rp: TimeInterval, bp: TimeInterval)], viewFrom: TimeInterval) -> (TimeInterval) -> Bool {
        let isDiscarded = memoizeRecursive { isDiscarded, ts in

            /// Returns whether an event is discarded or not by finding covering restore events and
            /// recursing to eliminate discarded restores.
            ///
            /// - Parameters:
            ///     - rp: Timestamp of "Restore Point" event.
            ///     - bp: Timestamp of "Backup Point" event.
            ///
            return ts > viewFrom ||
                   rewinds.contains(where: { (rp: TimeInterval, bp: TimeInterval) -> Bool in
                       return !(bp >= ts || ts >= rp || rp > viewFrom || isDiscarded(rp))
                   })
        }
        return isDiscarded
    }

    /// Extracts pairs of restore/backup timestamps from stream of Activity Log events.
    /// Returns pairs of [ restore event timestamp, associated backup event timestamp ].
    ///
    /// - Parameters:
    ///     - activities: Array of activities to process.
    ///
    class func getRewinds(activities: [Activity]) throws -> [(rp: TimeInterval, bp: TimeInterval)] {
        return try activities.filter({ (activity) -> Bool in
            activity.isRewindComplete
        }).map({ (activity) -> (rp: TimeInterval, bp: TimeInterval) in
            // Every rewind complete activity should have a 'target_ts'
            if let activityTargetTs = activity.object?.attributes["target_ts"] as? TimeInterval {
                return (activity.published.timeIntervalSince1970, activityTargetTs)
            } else {
                throw Error.missingTargetTimestampInRewind
            }
        })
    }

    /// Marks the received activities as discarded accordingly to the existing rewinds.
    ///
    /// - Parameters:
    ///     - activities: Array of activities to process.
    ///     - viewFrom: Timestamp of the "Point of Observation", defaults to now.
    ///
    class func rewriteStream(activities: [Activity], viewFrom: TimeInterval = Date().timeIntervalSince1970) throws -> [Activity] {
        let rewinds = try getRewinds(activities: activities).filter({ (rp: TimeInterval, bp: TimeInterval) -> Bool in
            rp <= viewFrom
        })
        let isDiscarded = makeIsDiscarded(rewinds: rewinds, viewFrom: viewFrom)

        return activities.map({ (activity) in
            activity.isDiscarded = isDiscarded(activity.published.timeIntervalSince1970)
            return activity
        })
    }

}

extension ActivityUtils {
    enum Error: Swift.Error {
        case missingTargetTimestampInRewind
    }
}

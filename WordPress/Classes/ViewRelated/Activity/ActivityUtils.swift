import Foundation

/// This is all based on Dennis Snell implementation on Calypso.
/// Keeping the same function and parameters names to be able to re use the documentation.
/// https://github.com/Automattic/wp-calypso/tree/master/client/state/activity-log/log/is-discarded
///
public class ActivityUtils {

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
}

extension ActivityUtils {
    enum Error: Swift.Error {
        case missingTargetTimestampInRewind
    }
}

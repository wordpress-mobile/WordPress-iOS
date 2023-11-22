import Foundation
import Pulse
import WordPressShared

final class DebugAnalyticsLogger: NSObject, WPAnalyticsTracker {
    static let analyticsLabel = "analytics"

    func track(_ stat: WPAnalyticsStat) {
        track(stat, withProperties: [:])
    }

    func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]!) {
        let pair = WPAnalyticsTrackerAutomatticTracks.eventPair(for: stat)
        var properties = pair.properties ?? [:]
        properties.merge(properties, uniquingKeysWith: { lhs, _ in lhs })
        trackString(pair.eventName, withProperties: properties)
    }

    func trackString(_ event: String!) {
        trackString(event, withProperties: [:])
    }

    func trackString(_ event: String!, withProperties properties: [AnyHashable: Any]!) {
        var metadata: [String: LoggerStore.MetadataValue] = [:]
        for (key, value) in properties {
            metadata[String(describing: key)] = .stringConvertible(MetadataValueConvertible(value: value))
        }
        LoggerStore.shared.storeMessage(label: DebugAnalyticsLogger.analyticsLabel, level: .trace, message: event, metadata: metadata)
    }
}

private struct MetadataValueConvertible: CustomStringConvertible {
    let value: Any

    var description: String {
        String(describing: value)
    }
}

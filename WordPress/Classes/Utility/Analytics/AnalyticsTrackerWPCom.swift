import Foundation
import WordPressShared

@objc public final class AnalyticsTrackerWPCom: NSObject, WPAnalyticsTracker {

    public func track(_ stat: WPAnalyticsStat) {
        track(stat, withProperties: nil)
    }

    public func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        switch stat {
        case .readerFreshlyPressedLoaded:
            pingWPComStatsEndpoint("freshly")
        case .readerArticleOpened:
            pingWPComStatsEndpoint("details_page")
        case .readerAccessed:
            pingWPComStatsEndpoint("home_page")
        default:
            break
        }
    }

    public func trackString(_ event: String) {
        // Only WPAnalyticsStat should be used in this Tracker
    }

    public func trackString(_ event: String, withProperties properties: [AnyHashable: Any]?) {
        // Only WPAnalyticsStat should be used in this Tracker
    }

    func pingWPComStatsEndpoint(_ statName: String) {
        let x = UInt32.random(in: 0..<UInt32.max)
        let statsURL = "https://en.wordpress.com/reader/mobile/v2/?chrome=no&template=stats&stats_name=\(statName)&rnd=\(x)"
        let userAgent = WPUserAgent.wordPress()

        var request = URLRequest(url: URL(string: statsURL)!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request).resume()
    }
}

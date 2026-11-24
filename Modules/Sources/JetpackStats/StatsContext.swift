import Foundation
import SwiftUI
import AsyncImageKit
@preconcurrency import WordPressKit

public struct StatsContext: Sendable {
    /// The reporting time zone (the time zone of the site).
    let timeZone: TimeZone
    let calendar: Calendar
    let service: any StatsServiceProtocol
    let formatters: StatsFormatters
    let siteID: Int
    /// A closure to preprocess avatar URLs to request the appropriate pixel size.
    public var preprocessAvatar: (@Sendable (URL, CGFloat) -> URL)?
    /// Analytics tracker for monitoring user interactions
    public var tracker: (any StatsTracker)?
    /// URL to upgrade the site's plan
    public var upgradeURL: URL?
    /// Authenticates requests for the site's own media. A private, Atomic or P2 site
    /// serves a featured image only to a signed request.
    public var mediaHost: (any MediaHostProtocol)?
    /// Whether the site is an Automattic P2. WordPress.com serves a P2's media from the
    /// site's own domain, so an image resizes from query parameters and the public image
    /// proxy can't fetch it.
    public var isAutomatticP2: Bool

    public init(
        timeZone: TimeZone,
        siteID: Int,
        api: WordPressComRestApi,
        postLikesStore: (any PostLikesStore)? = nil
    ) {
        self.init(
            timeZone: timeZone,
            siteID: siteID,
            service: StatsService(siteID: siteID, api: api, timeZone: timeZone, postLikesStore: postLikesStore)
        )
    }

    init(timeZone: TimeZone, siteID: Int, service: (any StatsServiceProtocol)) {
        self.siteID = siteID
        self.timeZone = timeZone
        self.calendar = {
            var calendar = Calendar.current
            calendar.timeZone = timeZone
            return calendar
        }()
        self.service = service
        self.formatters = StatsFormatters(timeZone: timeZone)
        self.preprocessAvatar = nil
        self.tracker = nil
        self.upgradeURL = nil
        self.mediaHost = nil
        self.isAutomatticP2 = false
    }

    public static let demo: StatsContext = {
        var context = StatsContext(timeZone: .current, siteID: 1, service: MockStatsService())
        #if DEBUG
        context.tracker = MockStatsTracker.shared
        context.upgradeURL = URL(string: "https://wordpress.com/pricing/")
        #endif
        return context
    }()

    /// Disables delays on the mock service.
    public func delaysDisabled(_ isDisabled: Bool = true) -> StatsContext {
        if let service = self.service as? MockStatsService {
            Task {
                await service.disableDelays()
            }
        }
        return self
    }

    /// Memoized formatted pre-configured to work with the reporting time zone.
    final class StatsFormatters: Sendable {
        let date: StatsDateFormatter
        let dateRange: StatsDateRangeFormatter

        init(timeZone: TimeZone) {
            self.date = StatsDateFormatter(timeZone: timeZone)
            self.dateRange = StatsDateRangeFormatter(timeZone: timeZone)
        }
    }
}

extension Calendar {
    static var demo: Calendar {
        StatsContext.demo.calendar
    }
}

// MARK: - Environment Key

private struct StatsContextKey: EnvironmentKey {
    static let defaultValue = StatsContext.demo
}

extension EnvironmentValues {
    var context: StatsContext {
        get { self[StatsContextKey.self] }
        set { self[StatsContextKey.self] = newValue }
    }
}

import Foundation
import SwiftUI
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
    /// Whether WordAds is enabled for this site
    public let isWordAdsEnabled: Bool

    public init(timeZone: TimeZone, siteID: Int, api: WordPressComRestApi, isWordAdsEnabled: Bool = false) {
        self.init(timeZone: timeZone, siteID: siteID, service: StatsService(siteID: siteID, api: api, timeZone: timeZone), isWordAdsEnabled: isWordAdsEnabled)
    }

    init(timeZone: TimeZone, siteID: Int, service: (any StatsServiceProtocol), isWordAdsEnabled: Bool = false) {
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
        self.isWordAdsEnabled = isWordAdsEnabled
    }

    public static let demo: StatsContext = {
        var context = StatsContext(timeZone: .current, siteID: 1, service: MockStatsService())
#if DEBUG
        context.tracker = MockStatsTracker.shared
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

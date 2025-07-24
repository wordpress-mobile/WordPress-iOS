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

    public init(timeZone: TimeZone, siteID: Int, api: WordPressComRestApi) {
        self.init(timeZone: timeZone, siteID: siteID, service: StatsService(siteID: siteID, api: api, timeZone: timeZone))
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
    }

    public static let demo = StatsContext(timeZone: .current, siteID: 1, service: MockStatsService())

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

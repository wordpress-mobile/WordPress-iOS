import Foundation
import Testing
@testable import Support

private let minute: TimeInterval = 60
private let hour: TimeInterval = 60 * minute
private let day: TimeInterval = 24 * hour

struct UnifiedSupportRelativeTimeTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000) // 2027-01-15 08:00:00 UTC

    @Test(arguments: [0, 59, -30] as [TimeInterval])
    func showsJustNowForTheLastMinute(secondsAgo: TimeInterval) {
        #expect(format(secondsAgo: secondsAgo) == "Just now")
    }

    @Test(arguments: [
        (minute, "1 minute ago"),
        (59 * minute, "59 minutes ago"),
        (hour, "1 hour ago"),
        (23 * hour, "23 hours ago"),
        (day, "1 day ago"),
        (6 * day, "6 days ago"),
        (7 * day, "1 week ago"),
        (29 * day, "4 weeks ago")
    ])
    func showsRelativeTimeForTheLast30Days(secondsAgo: TimeInterval, expected: String) {
        #expect(format(secondsAgo: secondsAgo) == expected)
    }

    @Test func showsTheDateAfter30Days() {
        #expect(format(secondsAgo: 30 * day) == "Dec 16, 2026")
    }

    private func format(secondsAgo: TimeInterval) -> String {
        UnifiedSupportRelativeTime.format(
            now.addingTimeInterval(-secondsAgo),
            relativeTo: now,
            locale: Locale(identifier: "en_US"),
            timeZone: TimeZone(identifier: "UTC")!
        )
    }
}

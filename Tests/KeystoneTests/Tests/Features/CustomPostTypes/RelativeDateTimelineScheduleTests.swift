import Foundation
import Testing

@testable import WordPress

@Suite("RelativeDateTimelineSchedule")
struct RelativeDateTimelineScheduleTests {
    private let date = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let week: TimeInterval = 7 * 24 * 60 * 60

    /// The first `count` entries, as offsets in seconds from the row date,
    /// when the schedule starts `start` seconds after the row date.
    private func offsets(startingAt start: TimeInterval, count: Int) -> [TimeInterval] {
        RelativeDateTimelineSchedule(date: date)
            .entries(from: date.addingTimeInterval(start), mode: .normal)
            .prefix(count)
            .map { $0.timeIntervalSince(date) }
    }

    @Test("ticks every second during the first minute, starting on the elapsed second")
    func ticksEverySecondDuringFirstMinute() {
        #expect(offsets(startingAt: 2.7, count: 4) == [2, 3, 4, 5])
    }

    @Test("switches to minute ticks once the date is a minute old")
    func switchesToMinuteTicksAtOneMinute() {
        #expect(offsets(startingAt: 57.5, count: 6) == [57, 58, 59, 60, 120, 180])
    }

    @Test("aligns minute ticks to the date rather than to the start")
    func alignsMinuteTicksToDate() {
        #expect(offsets(startingAt: 130.2, count: 3) == [120, 180, 240])
    }

    @Test("starts on the boundary itself when the start is one")
    func startsOnBoundary() {
        #expect(offsets(startingAt: 60, count: 2) == [60, 120])
    }

    @Test("ends on the one-week boundary, where the label turns absolute")
    func endsOnOneWeekBoundary() {
        #expect(offsets(startingAt: week - 61, count: 10) == [week - 120, week - 60, week])
    }

    @Test("emits only the start for a date older than a week")
    func emitsOnlyStartWhenOlderThanAWeek() {
        let start = 8 * 24 * 60 * 60 as TimeInterval
        #expect(offsets(startingAt: start, count: 10) == [start])
    }

    @Test("counts down by the second within a minute of a future date")
    func countsDownBeforeFutureDate() {
        #expect(offsets(startingAt: -30.5, count: 3) == [-31, -30, -29])
    }

    @Test("counts down by the minute further ahead of a future date")
    func countsDownMinutesBeforeFutureDate() {
        #expect(offsets(startingAt: -150.2, count: 3) == [-180, -120, -60])
    }

    @Test("emits one entry per second for a minute, then one per minute for the rest of the week")
    func entryCountOverAWeek() {
        let count = RelativeDateTimelineSchedule(date: date)
            .entries(from: date, mode: .normal)
            .reduce(0) { total, _ in total + 1 }
        #expect(count == 60 + 7 * 24 * 60)
    }
}

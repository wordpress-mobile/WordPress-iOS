import SwiftUI

/// Refreshes a label worded relative to `date` by `toMediumString` exactly when
/// its wording can change: every second within the first minute, every minute
/// until the label switches to an absolute date a week out, then never.
///
/// Entries are aligned to `date` rather than to when the view appeared, so
/// "45 seconds ago" becomes "1 minute ago" on the boundary instead of lagging
/// behind by up to one period.
struct RelativeDateTimelineSchedule: TimelineSchedule {
    let date: Date

    func entries(from startDate: Date, mode: Mode) -> UnfoldFirstSequence<Date> {
        sequence(first: firstEntry(atOrBefore: startDate), next: nextEntry(after:))
    }

    /// The boundary at or before `startDate`, so the first render already
    /// reflects the current wording. Falls back to `startDate` itself once the
    /// label is absolute, so the sequence is never empty.
    private func firstEntry(atOrBefore startDate: Date) -> Date {
        guard let step = step(at: startDate) else {
            return startDate
        }
        return boundary(atOrBefore: startDate, step: step)
    }

    private func nextEntry(after entry: Date) -> Date? {
        guard let step = step(at: entry) else {
            return nil
        }
        let next = boundary(atOrBefore: entry, step: step).addingTimeInterval(step)
        // Guard against floating point leaving `next` at or before `entry`.
        return max(next, entry.addingTimeInterval(step))
    }

    /// The tick aligned to `date` at or before `moment`.
    private func boundary(atOrBefore moment: Date, step: TimeInterval) -> Date {
        let elapsed = moment.timeIntervalSince(date)
        return date.addingTimeInterval((elapsed / step).rounded(.down) * step)
    }

    /// The interval between wording changes at `moment`, or nil once the label is absolute.
    private func step(at moment: Date) -> TimeInterval? {
        let distance = abs(date.timeIntervalSince(moment))
        switch distance {
        case ..<60:
            return 1
        case ..<(7 * 24 * 60 * 60):
            return 60
        default:
            return nil
        }
    }
}

import Foundation

/// Formats a video duration (seconds) as `m:ss` for durations under one hour
/// and `h:mm:ss` from one hour up. **Intentionally locale-neutral**: V1's
/// `DateComponentsFormatter`-based output varies in non-Latin-numeral
/// locales (Arabic, Hindi, etc.), but the duration badge uses a
/// `.monospaced` font and reads more like a timecode than a sentence — a
/// stable `digit:digit` output is the better fit. This is a small,
/// deliberate deviation from V1's `SiteMediaCollectionCellViewModel.swift`'s
/// `makeString(forDuration:)`.
enum MediaGridDuration {
    static func string(forSeconds seconds: UInt32) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

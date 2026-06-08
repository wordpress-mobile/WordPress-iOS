import Foundation
import os

/// Generates the temp-file basenames used for media uploads, and with them the
/// filenames WordPress ends up storing.
///
/// The uploaded media's filename is the basename of the file sent to the
/// server: `MediaCreateParams` carries no explicit filename, so the upload
/// layer (wordpress-rs) falls back to the last path component of the file it
/// uploads. Naming each temp file `<stem>.<ext>` from the source's own name is
/// therefore the whole of filename preservation (and, since the title is left
/// unset, drives the server-derived attachment title too).
///
/// Holds the basenames already handed out so repeated names within one uploader
/// session get ` (2)`, ` (3)` suffixes instead of overwriting each other.
final class UploadFilenameAllocator: Sendable {
    private let usedBasenames = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    /// The sanitized `preferred` name, or `<fallbackPrefix>-<timestamp>` when
    /// the source has no usable name. Carries no extension and is not yet
    /// deduplicated; pass the result to `basename`.
    func stem(preferred: String?, fallbackPrefix: String, date: Date) -> String {
        preferred.flatMap(sanitize) ?? "\(fallbackPrefix)-\(timestampedName(date: date))"
    }

    /// A unique `<stem>.<ext>` basename. Names already handed out for the
    /// lifetime of this allocator are tracked, so a batch with two same-named
    /// files becomes `name.jpg`, `name (2).jpg`, and so on.
    func basename(stem: String, ext: String) -> String {
        usedBasenames.withLock { used in
            let first = "\(stem).\(ext)"
            if used.insert(first).inserted {
                return first
            }
            var n = 2
            while true {
                let candidate = "\(stem) (\(n)).\(ext)"
                if used.insert(candidate).inserted {
                    return candidate
                }
                n += 1
            }
        }
    }

    /// Filesystem-safe `yyyy-MM-dd HH-mm-ss` timestamp (fixed POSIX locale)
    /// used to build fallback stems when a source has no name of its own.
    private func timestampedName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter.string(from: date)
    }

    /// Strips path separators and NUL, caps length, and treats an empty result
    /// as "no usable name" (nil) so the caller falls back to a generated stem.
    private func sanitize(_ name: String) -> String? {
        let cleaned =
            name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\u{0}", with: "")
        let trimmed = String(cleaned.prefix(256))
        return trimmed.isEmpty ? nil : trimmed
    }
}

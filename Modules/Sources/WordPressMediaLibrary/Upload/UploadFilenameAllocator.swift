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

    /// Upper bound on the name stem, in UTF-8 bytes. Kept well under APFS
    /// `NAME_MAX` (255 bytes) so the `.<ext>` and any ` (n)` dedup suffix still
    /// fit without per-candidate length arithmetic. A source name longer than
    /// this would otherwise make the temp-file write fail with `ENAMETOOLONG`.
    private static let maxStemBytes = 200

    /// The sanitized `preferred` name, or `<fallbackPrefix>-<timestamp>` when
    /// the source has no usable name. Carries no extension and is not yet
    /// deduplicated; pass the result to `basename`.
    func stem(preferred: String?, fallbackPrefix: String, date: Date) -> String {
        if let cleaned = preferred.map(sanitize), !cleaned.isEmpty {
            return cleaned
        }
        return "\(fallbackPrefix)-\(timestampedName(date: date))"
    }

    /// A unique `<stem>.<ext>` basename, safe to hand to
    /// `URL.appendingPathComponent`. The stem is sanitized and length-capped
    /// here (not only in `stem`), so a caller that passes a raw source name
    /// (`.remoteURL`, `.imagePlayground`) can't smuggle a path separator or an
    /// over-long name onto disk. Names already handed out for the lifetime of
    /// this allocator are tracked, so a batch with two same-named files becomes
    /// `name.jpg`, `name (2).jpg`, and so on.
    func basename(stem: String, ext: String) -> String {
        let fitted = truncated(sanitize(stem), toUTF8ByteCount: Self.maxStemBytes)
        let safeStem = fitted.isEmpty ? "file" : fitted
        return usedBasenames.withLock { used in
            let first = "\(safeStem).\(ext)"
            if used.insert(first).inserted {
                return first
            }
            var n = 2
            while true {
                let candidate = "\(safeStem) (\(n)).\(ext)"
                if used.insert(candidate).inserted {
                    return candidate
                }
                n += 1
            }
        }
    }

    /// Formatter for `timestampedName`. `DateFormatter` construction is
    /// expensive, and the class is documented thread-safe, so one shared
    /// instance serves every allocation.
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter
    }()

    /// Filesystem-safe `yyyy-MM-dd HH-mm-ss` timestamp (fixed POSIX locale)
    /// used to build fallback stems when a source has no name of its own.
    private func timestampedName(date: Date) -> String {
        Self.timestampFormatter.string(from: date)
    }

    /// Replaces path separators with `_` and strips NUL so the result is a
    /// single path component that `appendingPathComponent` can't use to escape
    /// its parent directory (e.g. `../escaped` becomes `.._escaped`). May be
    /// empty; `stem` treats that as "no usable name" and `basename` substitutes
    /// a stub.
    private func sanitize(_ name: String) -> String {
        name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\u{0}", with: "")
    }

    /// Truncates `name` to at most `maxBytes` UTF-8 bytes without splitting a
    /// grapheme, so the temp-file write can't fail with `ENAMETOOLONG` and the
    /// result is never cut mid-character.
    private func truncated(_ name: String, toUTF8ByteCount maxBytes: Int) -> String {
        guard name.utf8.count > maxBytes else { return name }
        var result = ""
        var count = 0
        for character in name {
            let size = String(character).utf8.count
            if count + size > maxBytes {
                break
            }
            result.append(character)
            count += size
        }
        return result
    }
}

import Foundation
import WordPressAPI

/// Filename derivation for the Share action. The primitive `suggested(...)`
/// form is the canonical implementation; both the single-item detail VM
/// (which has a `MediaDetailDisplayModel` snapshot) and the bulk-share
/// path (which has a `MediaWithEditContext`) call through to it via
/// matching primitive fields. The `suggested(for media:)` overload is a
/// convenience for the bulk path.
enum MediaShareFilename {
    /// Picks a human-meaningful filename in this priority order: trimmed
    /// title, trimmed slug, URL last-path-component, then "media-<id>".
    /// Returns `nil` only if every fallback also fails; production callers
    /// always have an `id`, so the "media-<id>" tail is the effective floor.
    ///
    /// Each candidate is checked with `isUsable(_:)`, which rejects the
    /// filesystem-special components `.` and `..` (and the empty string).
    /// Title and slug are user-controlled site data; without the rejection,
    /// a literal "." title with no MIME-derived extension would resolve to
    /// the batch directory itself when appended as a path component, and
    /// the share `moveItem` would fail silently.
    static func suggested(title: String?, slug: String, sourceUrl: String, id: Int64) -> String? {
        let trimmedTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if isUsable(trimmedTitle) { return trimmedTitle }

        let trimmedSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        if isUsable(trimmedSlug) { return trimmedSlug }

        if let last = URL(string: sourceUrl)?.lastPathComponent, isUsable(last) {
            return last
        }

        return "media-\(id)"
    }

    private static func isUsable(_ candidate: String) -> Bool {
        !candidate.isEmpty && candidate != "." && candidate != ".."
    }

    /// Convenience for callers that already hold a full `MediaWithEditContext`
    /// (the bulk-share path in `MediaLibraryViewModel.startBulkShare()`).
    static func suggested(for media: MediaWithEditContext) -> String? {
        suggested(title: media.title.raw, slug: media.slug, sourceUrl: media.sourceUrl, id: media.id)
    }
}

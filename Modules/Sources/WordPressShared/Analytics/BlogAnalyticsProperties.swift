import Foundation

/// A `Sendable`, value-type snapshot of the site facts that analytics attaches
/// to an event.
///
/// Analytics only needs a couple of scalars about a site — its WordPress.com ID
/// and whether it's a P2 — but historically those were read straight off a Core
/// Data `Blog` at the point of tracking, on whatever thread the caller happened
/// to be on. Reading a managed object off its context's queue is a Core Data
/// threading violation, and `Blog.dotComID`'s getter can *write* back to the
/// object. Capturing the facts in this value type moves the read to a single,
/// controlled place and lets only a `Sendable` snapshot cross into the analytics
/// layer.
///
/// - SeeAlso: ``BlogAnalyticsRepresentable``
public struct BlogAnalyticsProperties: Equatable, Sendable {
    /// The site's WordPress.com ID (the `blog_id` property). `nil` for
    /// self-hosted sites.
    ///
    /// `Int` rather than `Int64` so it satisfies a consumer's `as? Int` after the
    /// analytics dictionary round-trips through Objective-C; `Int` is 64-bit on
    /// every supported platform, so no blog ID is truncated.
    public let dotComID: Int?

    /// Whether the site is a WordPress for Teams (P2) site. Drives the
    /// `site_type` property.
    public let isWPForTeams: Bool

    public init(dotComID: Int?, isWPForTeams: Bool) {
        self.dotComID = dotComID
        self.isWPForTeams = isWPForTeams
    }
}

/// A type that can describe itself to the analytics layer as a value.
///
/// Conform model types (e.g. `Blog`) to this protocol so callers can hand
/// analytics a `Sendable` ``BlogAnalyticsProperties`` snapshot instead of a live
/// Core Data object. Only the snapshot crosses the model boundary, which keeps
/// the analytics layer free of Core Data — and free of the threading hazards
/// that come with it.
public protocol BlogAnalyticsRepresentable {
    /// A value-type snapshot of the site facts analytics needs.
    ///
    /// A conformance that wraps a managed object must produce this snapshot on
    /// the object's context queue.
    var analyticsProperties: BlogAnalyticsProperties { get }
}

import Foundation
import WordPressAPI
import WordPressCore
import WordPressShared

/// Resolves post titles for comment rows. Core REST comments carry only a
/// post ID; titles arrive from a separate batched request and fill in
/// asynchronously. One instance per screen, shared by every tab's view model,
/// so the same title is never fetched twice.
///
/// Resolution is best-effort by design: a failure never blocks or fails the
/// comments list, it only leaves rows in the author-only presentation.
@MainActor
final class PostTitleResolver: ObservableObject {
    /// A fetcher's outcome for one batch: the titles it resolved, and the IDs it
    /// could not resolve because a lookup errored (as opposed to authoritatively
    /// returning no match). Resolved titles are kept even when some IDs fail, so
    /// a partial-endpoint failure never discards titles that did come back; only
    /// the `retryable` IDs re-enter the resolve queue.
    struct FetchResult: Sendable {
        var titles: [Int64: String]
        var retryable: Set<Int64>

        init(titles: [Int64: String], retryable: Set<Int64> = []) {
            self.titles = titles
            self.retryable = retryable
        }
    }

    typealias Fetcher = @Sendable (_ ids: [Int64]) async throws -> FetchResult

    enum TitleState: Equatable {
        case resolved(String)
        case loading
        case unavailable
    }

    @Published private(set) var titles: [Int64: String] = [:]

    private let fetcher: Fetcher
    private var inFlight: Set<Int64> = []
    /// Fetched successfully but not returned (deleted post, or a custom post
    /// type the fetcher's endpoints don't cover). Never refetched.
    /// Published so a row moving from `.loading` to `.unavailable` triggers a
    /// view update even though `titles` is untouched.
    @Published private var notFound: Set<Int64> = []
    /// Fetch threw. Shown as unavailable, but retried on the next resolve()
    /// that references them. Published for the same reason as `notFound`.
    @Published private var failed: Set<Int64> = []

    init(fetcher: @escaping Fetcher) {
        self.fetcher = fetcher
    }

    func titleState(for postID: Int64) -> TitleState {
        if let title = titles[postID] {
            return .resolved(title)
        }
        if notFound.contains(postID) || failed.contains(postID) {
            return .unavailable
        }
        return .loading
    }

    func resolve(ids: [Int64]) {
        Task { await resolveAndWait(ids: ids) }
    }

    func resolveAndWait(ids: [Int64]) async {
        let pending = Set(ids)
            .subtracting(titles.keys)
            .subtracting(inFlight)
            .subtracting(notFound)
        guard !pending.isEmpty else { return }
        failed.subtract(pending)
        inFlight.formUnion(pending)
        defer { inFlight.subtract(pending) }
        do {
            let result = try await fetcher(Array(pending))
            titles.merge(result.titles) { _, new in new }
            failed.formUnion(result.retryable)
            // Neither resolved nor flagged retryable means the lookup completed
            // and authoritatively found no match (deleted post or a custom post
            // type the endpoints don't cover): never refetched.
            notFound.formUnion(
                pending.subtracting(result.titles.keys).subtracting(result.retryable)
            )
        } catch {
            failed.formUnion(pending)
        }
    }

    /// Fetches id + title for regular posts, then retries the remainder
    /// against pages. Custom post types are not covered in M1 and resolve to
    /// unavailable.
    /// TODO: Read the wordpress-rs cache as a first tier once it exposes a
    /// public by-post-ID lookup; today only cache-internal EntityId reads
    /// exist, and direct sqlite access is off limits.
    /// TODO: Consider making this a plain nonisolated async function
    /// (`liveFetch(ids:client:)`) wrapped in a `Fetcher` closure at the call
    /// site, instead of a factory that returns a closure. Deferred for now.
    static func liveFetcher(client: WordPressClient) -> Fetcher {
        { ids in
            func fetch(_ ids: [Int64], from endpoint: PostEndpointType) async throws -> [Int64: String] {
                let response = try await client.api.posts.filterListWithViewContext(
                    postEndpointType: endpoint,
                    params: PostListParams(perPage: UInt32(ids.count), include: ids),
                    fields: [.id, .title]
                )
                var titles: [Int64: String] = [:]
                for post in response.data {
                    guard let id = post.id, let rendered = post.title?.rendered else {
                        continue
                    }
                    // `rendered` is HTML; strip it to plain text so entities and
                    // markup don't leak into the row. Skip an empty title so the
                    // row falls back to author-only instead of showing a
                    // dangling "Author on " headline.
                    let title = rendered.makePlainText()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !title.isEmpty {
                        titles[id] = title
                    }
                }
                return titles
            }

            var titles = try await fetch(ids, from: .posts)
            let remainder = ids.filter { titles[$0] == nil }
            guard !remainder.isEmpty else {
                return FetchResult(titles: titles)
            }
            // A comment on a page is as common as one on a post, so the
            // remainder must be looked up rather than assumed absent. If the
            // pages lookup fails, keep the post titles already resolved and
            // report only the remainder as retryable, so a transient failure
            // never discards good titles or permanently hides those IDs.
            do {
                let pageTitles = try await fetch(remainder, from: .pages)
                titles.merge(pageTitles) { _, new in new }
                return FetchResult(titles: titles)
            } catch {
                return FetchResult(titles: titles, retryable: Set(remainder))
            }
        }
    }
}

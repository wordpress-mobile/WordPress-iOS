import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// Resolves featured media ids to image URLs once per list, so every row can
/// tell whether it has an image before its own lookup would have landed.
///
/// The card list picks its row shape from this: a post whose media is pending
/// or resolved takes the hero shape, one whose lookup failed falls back to the
/// compact shape rather than shimmering indefinitely.
@MainActor
final class FeaturedMediaURLCache {
    enum State: Equatable {
        case pending
        case resolved(URL)
        case unresolvable
    }

    /// One media id's state. Rows observe their own entry rather than the
    /// cache, so an image landing does not invalidate every other row.
    @MainActor
    final class Entry: ObservableObject {
        @Published fileprivate(set) var state: State

        fileprivate init(state: State) {
            self.state = state
        }
    }

    typealias Resolve = @Sendable (MediaId) async throws -> URL?

    /// Handed out for every id the API cannot have. Kept out of `entries` so
    /// it is never retried.
    private static let unresolvable = Entry(state: .unresolvable)

    private let resolve: Resolve
    private var entries: [MediaId: Entry] = [:]
    private var tasks: [MediaId: Task<Void, Never>] = [:]
    private var visibleIDs: Set<MediaId> = []

    convenience init(client: WordPressClient) {
        self.init { mediaId in
            let response = try await client.api.media.retrieveWithViewContext(mediaId: mediaId)
            return URL(string: response.data.sourceUrl)
        }
    }

    init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }

    /// The entry for `mediaId`, created on first ask.
    func entry(for mediaId: MediaId) -> Entry {
        guard mediaId > 0 else { return Self.unresolvable }
        if let entry = entries[mediaId] {
            return entry
        }
        let entry = Entry(state: .pending)
        entries[mediaId] = entry
        return entry
    }

    func mediaDidAppear(_ mediaId: MediaId) {
        visibleIDs.insert(mediaId)
        resolveIfNeeded(mediaId)
    }

    func mediaDidDisappear(_ mediaId: MediaId) {
        visibleIDs.remove(mediaId)
    }

    func resolveIfNeeded(_ mediaId: MediaId) {
        guard entry(for: mediaId).state == .pending, tasks[mediaId] == nil else { return }
        startResolving(mediaId)
    }

    /// Gives the lookups that failed another go.
    ///
    /// Rows on screen will not ask again on their own, so their lookups are
    /// restarted here; the entry stays `.unresolvable` until a retry actually
    /// lands, so a second failure changes nothing visible. Rows off screen just
    /// go back to pending and ask when they next appear, which keeps a refresh
    /// from fanning out one request per failure the user ever scrolled past.
    func retryFailures() {
        for (mediaId, entry) in entries where entry.state == .unresolvable {
            if visibleIDs.contains(mediaId) {
                startResolving(mediaId)
            } else {
                entry.state = .pending
            }
        }
    }

    /// Waits for every lookup started so far. Test support.
    func awaitInFlightResolutions() async {
        for task in tasks.values {
            await task.value
        }
    }

    private func startResolving(_ mediaId: MediaId) {
        guard tasks[mediaId] == nil else { return }
        tasks[mediaId] = Task { [resolve] in
            let state: State
            do {
                state = try await resolve(mediaId).map(State.resolved) ?? .unresolvable
            } catch {
                Loggers.app.error("Failed to resolve featured media \(mediaId): \(error)")
                state = .unresolvable
            }
            entry(for: mediaId).state = state
            tasks[mediaId] = nil
        }
    }
}

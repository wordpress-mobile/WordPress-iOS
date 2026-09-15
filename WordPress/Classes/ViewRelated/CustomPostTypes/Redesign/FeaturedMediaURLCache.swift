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
final class FeaturedMediaURLCache: ObservableObject {
    enum State: Equatable {
        case pending
        case resolved(URL)
        case unresolvable
    }

    @Published private(set) var states: [MediaId: State] = [:]

    private let client: WordPressClient
    private var tasks: [MediaId: Task<Void, Never>] = [:]

    init(client: WordPressClient) {
        self.client = client
    }

    func state(for mediaId: MediaId) -> State {
        guard mediaId > 0 else { return .unresolvable }
        return states[mediaId] ?? .pending
    }

    func resolveIfNeeded(_ mediaId: MediaId) {
        guard mediaId > 0, states[mediaId] == nil, tasks[mediaId] == nil else { return }
        tasks[mediaId] = Task { [client] in
            let state: State
            do {
                let response = try await client.api.media.retrieveWithViewContext(mediaId: mediaId)
                state = URL(string: response.data.sourceUrl).map(State.resolved) ?? .unresolvable
            } catch {
                Loggers.app.error("Failed to resolve featured media \(mediaId): \(error)")
                state = .unresolvable
            }
            states[mediaId] = state
            tasks[mediaId] = nil
        }
    }

    /// Forgets failed lookups so a refresh gives them another go.
    func retryFailures() {
        states = states.filter { $0.value != .unresolvable }
    }
}

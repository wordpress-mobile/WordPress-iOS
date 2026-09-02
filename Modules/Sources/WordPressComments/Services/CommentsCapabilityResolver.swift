/// Resolves the moderation capability once per comments session and caches
/// the answer, so every detail screen can read it synchronously at init (its
/// toolbar and nav bar items then render on the first frame and take part in
/// the push transition). Concurrent callers share one lookup. A failed lookup
/// is not cached: the value stays nil and the next call retries.
@MainActor
final class CommentsCapabilityResolver {
    /// The capability once a lookup succeeded; nil while unknown.
    private(set) var canModerate: Bool?

    private let capabilities: any CommentsCapabilitiesProtocol
    private var lookup: Task<Bool?, Never>?

    init(capabilities: any CommentsCapabilitiesProtocol) {
        self.capabilities = capabilities
    }

    /// Starts a lookup unless the answer is known or one is already running.
    func prefetch() {
        guard canModerate == nil else { return }
        _ = lookupIfNeeded()
    }

    /// The cached answer, else the result of the running or a fresh lookup.
    /// Nil when that lookup fails.
    func resolve() async -> Bool? {
        if let canModerate { return canModerate }
        return await lookupIfNeeded().value
    }

    private func lookupIfNeeded() -> Task<Bool?, Never> {
        if let lookup { return lookup }
        let task = Task { [weak self, capabilities] () -> Bool? in
            let result = try? await capabilities.canModerateComments()
            self?.canModerate = result
            self?.lookup = nil
            return result
        }
        lookup = task
        return task
    }
}

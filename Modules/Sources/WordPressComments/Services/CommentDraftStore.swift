import Foundation

/// Persists in-progress reply drafts per (site, user, comment), matching the
/// legacy composer's behavior so a half-written reply survives cancel and
/// process death. Edit mode deliberately has no drafts (legacy parity).
@MainActor
public protocol CommentDraftStoring {
    func loadDraft(commentID: Int64) -> String?
    func saveDraft(_ text: String, commentID: Int64)
    func deleteDraft(commentID: Int64)
}

@MainActor
public final class UserDefaultsCommentDraftStore: CommentDraftStoring {
    private let namespace: String
    private let defaults: UserDefaults

    /// `namespace` identifies the (site, user) pair so drafts never leak
    /// across sites or accounts; see `namespace(siteURL:username:)`.
    init(namespace: String, defaults: UserDefaults = .standard) {
        self.namespace = namespace
        self.defaults = defaults
    }

    public convenience init(siteURL: URL, username: String, defaults: UserDefaults = .standard) {
        self.init(namespace: Self.namespace(siteURL: siteURL, username: username), defaults: defaults)
    }

    /// Keys drafts per (site, user): same person different site, or same
    /// site different account, must never see each other's drafts. Only the
    /// case-insensitive URL parts (scheme, host) are normalized; the path is
    /// case-sensitive, so lowercasing the whole URL would collapse distinct
    /// sites like /Blog and /blog and leak drafts between them.
    static func namespace(siteURL: URL, username: String) -> String {
        guard var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return "\(siteURL.absoluteString)|\(username)"
        }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        return "\(components.string ?? siteURL.absoluteString)|\(username)"
    }

    private func key(_ commentID: Int64) -> String {
        "CommentsV2Draft.\(namespace).\(commentID)"
    }

    public func loadDraft(commentID: Int64) -> String? {
        defaults.string(forKey: key(commentID))
    }

    public func saveDraft(_ text: String, commentID: Int64) {
        defaults.set(text, forKey: key(commentID))
    }

    public func deleteDraft(commentID: Int64) {
        defaults.removeObject(forKey: key(commentID))
    }
}

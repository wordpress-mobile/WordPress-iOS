import Foundation
import WordPressShared

/// Metadata used by the app.
public struct PostMetadata: Hashable {
    /// Gets or sets the Jetpack Newsletter access level as a PostAccessLevel enum
    public var accessLevel: JetpackPostAccessLevel?

    /// Returns `true` if the post is configured to _not_ be sent in an email
    /// to subscribers.
    public var isJetpackNewsletterEmailDisabled: Bool

    /// Initialized metadata with the given post.
    public init(_ post: AbstractPost) {
        self = PostMetadata(from: PostMetadataContainer(post))
    }

    public init(from container: PostMetadataContainer) {
        self.accessLevel = container.accessLevel
        self.isJetpackNewsletterEmailDisabled = container.getAdaptiveBool(for: .jetpackNewsletterEmailDisabled)
    }

    /// Applies the metadata values to the container and returns them
    /// as metadata values.
    public func encode(in container: inout PostMetadataContainer) {
        let previous = PostMetadata(from: container)
        if previous.accessLevel != accessLevel {
            container.accessLevel = accessLevel
        }
        if previous.isJetpackNewsletterEmailDisabled != isJetpackNewsletterEmailDisabled {
            container.setValue(String(describing: isJetpackNewsletterEmailDisabled), for: .jetpackNewsletterEmailDisabled)
        }
    }

    /// Returns all metadata values encoded in `PostMetadataContainer` as
    /// WordPress metadata fields.
    ///
    /// - note: It returns _only_ the fields managed by the app so that we
    /// don't send more than needed to the server when updating it.
    public static func entries(in container: PostMetadataContainer) -> [[String: Any]] {
        PostMetadata.allKeys.compactMap(container.entry)
    }

    /// Returns all keys managed by the app.
    public static let allKeys: [PostMetadataContainer.Key] = [
        .jetpackNewsletterAccess,
        .jetpackNewsletterEmailDisabled
    ]
}

/// Valid access levels for Jetpack Newsletter
public enum JetpackPostAccessLevel: String, CaseIterable, Hashable, Codable {
    case everybody = "everybody"
    case subscribers = "subscribers"
    case paidSubscribers = "paid_subscribers"
}

private extension PostMetadataContainer {
    var accessLevel: JetpackPostAccessLevel? {
        get {
            guard let value = getString(for: .jetpackNewsletterAccess) else { return nil }
            return JetpackPostAccessLevel(rawValue: value)
        }
        set {
            if let newValue {
                setValue(newValue.rawValue, for: .jetpackNewsletterAccess)
            } else {
                removeValue(for: .jetpackNewsletterAccess)
            }
        }
    }
}

extension PostMetadataContainer.Key {
    static let jetpackNewsletterAccess: PostMetadataContainer.Key = "_jetpack_newsletter_access"
    static let jetpackNewsletterEmailDisabled: PostMetadataContainer.Key = "_jetpack_dont_email_post_to_subs"
}

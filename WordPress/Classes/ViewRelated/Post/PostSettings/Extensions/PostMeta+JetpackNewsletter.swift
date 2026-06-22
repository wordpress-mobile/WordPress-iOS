import Foundation
import WordPressAPIInternal
import WordPressData

extension PostMeta {
    /// The Jetpack Newsletter access level stored in this meta, if any.
    ///
    /// Jetpack registers `_jetpack_newsletter_access` for the built-in `post`
    /// type only (see `extensions/blocks/subscriptions/subscriptions.php` in
    /// the Jetpack plugin).
    var jetpackNewsletterAccess: JetpackPostAccessLevel? {
        guard case let .string(raw)? = valueForKey(key: Self.newsletterAccessKey) else {
            return nil
        }
        return JetpackPostAccessLevel(rawValue: raw)
    }

    /// Returns a new `PostMeta` with the access level set. Pass `nil` to
    /// clear any previously-saved value.
    func addingJetpackNewsletterAccess(_ accessLevel: JetpackPostAccessLevel?) -> PostMeta {
        let value: JsonValue = accessLevel.map { .string($0.rawValue) } ?? .null
        return withValue(key: Self.newsletterAccessKey, value: value)
    }

    /// Whether the post is configured to NOT be sent in an email to
    /// subscribers. Defaults to `false` when the key is absent, matching
    /// `PostMetadataContainer.getAdaptiveBool` semantics.
    var isJetpackNewsletterEmailDisabled: Bool {
        guard case let .bool(value)? = valueForKey(key: Self.dontEmailKey) else {
            return false
        }
        return value
    }

    /// Returns a new `PostMeta` with the "don't email" flag set.
    func addingJetpackNewsletterEmailDisabled(_ disabled: Bool) -> PostMeta {
        withValue(key: Self.dontEmailKey, value: .bool(disabled))
    }

    private static let newsletterAccessKey = "_jetpack_newsletter_access"
    private static let dontEmailKey = "_jetpack_dont_email_post_to_subs"
}

import Foundation
import WordPressAPIInternal

extension PostMeta {
    /// The Jetpack publicize message stored in this meta, if any.
    ///
    /// The publicize plugin reads this from `_wpas_mess` post meta, registered
    /// via `register_meta` and exposed at `meta.jetpack_publicize_message`.
    /// Empty strings are reported as `nil` since the server treats them as
    /// "no override".
    public var publicizeMessage: String? {
        guard case let .string(text)? = valueForKey(key: Self.publicizeMessageKey), !text.isEmpty else {
            return nil
        }
        return text
    }

    /// Returns a new `PostMeta` with the publicize message set to the given
    /// string. Pass an empty string to clear a previously-saved value during a
    /// partial update.
    public func addingPublicizeMessage(_ message: String) -> PostMeta {
        self.withValue(key: Self.publicizeMessageKey, value: .string(message))
    }

    private static let publicizeMessageKey = "jetpack_publicize_message"
}

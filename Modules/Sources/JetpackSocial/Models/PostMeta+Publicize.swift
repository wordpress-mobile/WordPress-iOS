import Foundation
import WordPressAPIInternal

extension PostMeta {
    /// Returns a new `PostMeta` with `jetpack_publicize_message` set to the
    /// given message string. The publicize plugin reads this from `_wpas_mess`
    /// post meta, registered via `register_meta` and exposed at
    /// `meta.jetpack_publicize_message`.
    public func addingPublicizeMessage(_ message: String) -> PostMeta {
        self.withValue(key: "jetpack_publicize_message", value: .string(message))
    }
}

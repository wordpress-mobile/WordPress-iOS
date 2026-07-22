import AppIntents
import Foundation
import WordPressData

/// Offers only posts that can actually be published or scheduled, unlike the
/// entity's default query which covers all posts and pages.
///
/// This provider only feeds the Shortcuts-editor picker. Free-text
/// resolution (Siri voice, "Ask Each Time") still goes through the entity's
/// default query, so an unpublishable pick is possible there and is rejected
/// by the intents with a specific blocker error instead.
struct PublishablePostOptionsProvider: DynamicOptionsProvider {
    @MainActor
    func results() async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return Post.recentForAppIntentPublishing(in: context).compactMap { PostEntity(post: $0) }
    }
}

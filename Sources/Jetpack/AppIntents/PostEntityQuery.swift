import AppIntents
import Foundation
import WordPressData

/// Resolves and searches `PostEntity` values from the local Core Data store.
struct PostEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [PostEntity.ID]) async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return identifiers.compactMap { identifier in
            AbstractPost.forAppIntent(identifier: identifier, in: context).flatMap(PostEntity.init(post:))
                ?? PostEntity(identifier: identifier)
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return AbstractPost.searchForAppIntent(matching: string, in: context).compactMap { PostEntity(post: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return AbstractPost.searchForAppIntent(matching: "", limit: 10, in: context).compactMap { PostEntity(post: $0) }
    }
}

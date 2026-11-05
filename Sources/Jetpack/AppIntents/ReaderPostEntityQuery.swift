import AppIntents
import Foundation
import WordPressData

/// Resolves and searches `ReaderPostEntity` values from the local Core Data store.
struct ReaderPostEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [ReaderPostEntity.ID]) async throws -> [ReaderPostEntity] {
        let context = ContextManager.shared.mainContext
        return identifiers.compactMap { identifier in
            ReaderPost.forAppIntent(identifier: identifier, in: context).flatMap(ReaderPostEntity.init(post:))
                ?? ReaderPostEntity(identifier: identifier)
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ReaderPostEntity] {
        let context = ContextManager.shared.mainContext
        return ReaderPost.searchForAppIntent(matching: string, in: context).compactMap { ReaderPostEntity(post: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ReaderPostEntity] {
        let context = ContextManager.shared.mainContext
        return ReaderPost.searchForAppIntent(matching: "", limit: 10, in: context)
            .compactMap {
                ReaderPostEntity(post: $0)
            }
    }
}

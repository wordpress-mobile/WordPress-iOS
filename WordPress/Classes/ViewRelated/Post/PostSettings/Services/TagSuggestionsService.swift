import Foundation
import WordPressData
import WordPressShared

@MainActor
final class TagSuggestionsService {
    let coreData: CoreDataStack

    init(coreData: CoreDataStack = ContextManager.shared) {
        self.coreData = coreData
    }

    func getSuggestedTags(for post: AbstractPost) async throws -> [String] {
        wpAssert(post.managedObjectContext === coreData.mainContext)

        guard FeatureFlag.intelligence.enabled,
              #available(iOS 26, *),
              let post = post as? Post,
              !post.isContentEmpty() else {
            return []
        }

        let postContent = post.content ?? ""
        let postTags = AbstractPost.makeTags(from: post.tags ?? "")
        let siteTags = await getSiteTags(for: post.blog)

        guard postTags.count < 10 else {
            // It's full – let's not waste resources suggesting even more
            return []
        }

        try Task.checkCancellation()

        return try await IntelligenceService().suggestTags(
            post: postContent,
            siteTags: siteTags,
            postTags: postTags
        )
    }

    private func getSiteTags(for blog: Blog) async -> [String] {
        // Extract tag names while on main actor to avoid Sendable issues
        let existingTagNames = blog.tags?.compactMap { $0.name } ?? []
        if existingTagNames.isEmpty {
            let syncedTags = (try? await syncTags(for: blog)) ?? []
            return syncedTags.compactMap { $0.name }
        }
        // Refresh in the background without blocking progress
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            let blog = try coreData.mainContext.existingObject(with: blogID)
            try await syncTags(for: blog)
        }
        return existingTagNames
    }

    @discardableResult
    private func syncTags(for blog: Blog) async throws -> [PostTag] {
        try await withUnsafeThrowingContinuation { continuation in
            PostTagService(managedObjectContext: coreData.mainContext)
                .syncTags(for: blog) { tags in
                    continuation.resume(returning: tags)
                } failure: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}

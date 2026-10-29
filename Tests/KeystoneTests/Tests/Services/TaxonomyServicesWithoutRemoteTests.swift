import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

/// A WordPress.com blog whose account has no token has no remote. Category and tag requests for it must fail instead
/// of never calling back.
@MainActor
struct TaxonomyServicesWithoutRemoteTests {
    private let contextManager = ContextManager.forTesting()
    private let blog: Blog

    init() {
        blog = RemoteSelectionBlogFixture.dotComBlog(authToken: nil, context: contextManager.mainContext)
    }

    // MARK: - Categories

    @Test func syncCategoriesFails() {
        let error = failureError { failure in
            categoryService.syncCategories(
                for: blog,
                success: { Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isCategoryNoRemoteError(error))
    }

    @Test func syncCategoriesPageFails() {
        let error = failureError { failure in
            categoryService.syncCategories(
                for: blog,
                number: nil,
                offset: nil,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isCategoryNoRemoteError(error))
    }

    @Test func createCategoryFails() {
        let error = failureError { failure in
            categoryService.createCategory(
                withName: "Category",
                parentCategoryObjectID: nil,
                forBlogObjectID: blog.objectID,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isCategoryNoRemoteError(error))
    }

    // MARK: - Tags

    @Test func syncTagsFails() {
        let error = failureError { failure in
            tagService.syncTags(
                for: blog,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
    }

    @Test func syncTagsPageFails() {
        let error = failureError { failure in
            tagService.syncTags(
                for: blog,
                number: nil,
                offset: nil,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
    }

    @Test func getTopTagsFails() {
        let error = failureError { failure in
            tagService.getTopTags(
                for: blog,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
    }

    @Test func searchTagsFails() {
        let error = failureError { failure in
            tagService.searchTags(
                withName: "tag",
                blog: blog,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
    }

    @Test func deleteTagFailsAndKeepsTheTag() {
        let tag = PostTag(context: contextManager.mainContext)
        tag.tagID = 1

        let error = failureError { failure in
            tagService.delete(
                tag,
                for: blog,
                success: { Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
        #expect(!tag.isDeleted)
    }

    @Test func saveNewTagFails() {
        let tag = PostTag(context: contextManager.mainContext)
        tag.tagID = -1

        let error = failureError { failure in
            tagService.save(
                tag,
                for: blog,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
    }

    @Test func updateExistingTagFails() {
        let tag = PostTag(context: contextManager.mainContext)
        tag.tagID = 1

        let error = failureError { failure in
            tagService.save(
                tag,
                for: blog,
                success: { _ in Issue.record("Must not succeed without a remote") },
                failure: failure
            )
        }
        #expect(isTagNoRemoteError(error))
    }

    // MARK: - Helpers

    private var categoryService: PostCategoryService {
        PostCategoryService(coreDataStack: contextManager)
    }

    private var tagService: PostTagService {
        PostTagService(managedObjectContext: contextManager.mainContext)
    }

    /// Returns the error passed to the failure callback. Without a remote, the services call it before returning.
    private func failureError(_ request: (@escaping (Error) -> Void) -> Void) -> NSError? {
        var received: NSError?
        request { received = $0 as NSError }
        return received
    }

    private func isCategoryNoRemoteError(_ error: NSError?) -> Bool {
        error?.domain == String(describing: PostCategoryService.self)
            && error?.code == PostCategoryServiceErrors.noRemoteForBlog.rawValue
    }

    private func isTagNoRemoteError(_ error: NSError?) -> Bool {
        error?.domain == PostTagServiceErrorDomain && error?.code == PostTagServiceError.noRemoteForBlog.rawValue
    }
}

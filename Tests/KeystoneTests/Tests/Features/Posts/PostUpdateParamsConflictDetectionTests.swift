import Testing
import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
@testable import WordPress

@MainActor
struct PostUpdateParamsConflictDetectionTests {

    // MARK: - hasConflicts(from:to:) Tests

    @Test("No conflict when client and server change different fields")
    func hasFieldConflictsReturnsFalseForDifferentFields() {
        let original = makeRemotePost(slug: "original-slug")
        let latest = makeRemotePost(
            slug: "original-slug",
            status: .publish // Server changed status
        )
        var params = PostUpdateParams(meta: nil)
        params.slug = "new-slug" // Client changes slug

        #expect(!params.hasConflicts(from: original, to: latest))
    }

    @Test("Conflict when client and server both change the same field to different values")
    func hasFieldConflictsReturnsTrueForSameFieldDifferentValues() {
        let original = makeRemotePost(slug: "original-slug")
        let latest = makeRemotePost(slug: "server-slug")
        var params = PostUpdateParams(meta: nil)
        params.slug = "client-slug"

        #expect(params.hasConflicts(from: original, to: latest))
    }

    @Test("No conflict when client and server converge to the same value")
    func hasFieldConflictsReturnsFalseWhenConverged() {
        let original = makeRemotePost(slug: "original-slug")
        let latest = makeRemotePost(slug: "same-slug")
        var params = PostUpdateParams(meta: nil)
        params.slug = "same-slug"

        #expect(!params.hasConflicts(from: original, to: latest))
    }

    @Test("No conflict when server is unchanged and client changes fields")
    func hasFieldConflictsReturnsFalseWhenServerUnchanged() {
        let original = makeRemotePost(slug: "original-slug")
        let latest = makeRemotePost(slug: "original-slug")
        var params = PostUpdateParams(meta: nil)
        params.slug = "client-slug"

        #expect(!params.hasConflicts(from: original, to: latest))
    }

    @Test("No conflict when params are empty")
    func hasFieldConflictsReturnsFalseForEmptyParams() {
        let original = makeRemotePost(slug: "original-slug")
        let latest = makeRemotePost(slug: "server-slug")
        let params = PostUpdateParams(meta: nil)

        #expect(!params.hasConflicts(from: original, to: latest))
    }

    @Test("Conflict on title change")
    func hasFieldConflictsDetectsTitleConflict() {
        let original = makeRemotePost(
            title: PostTitleWithEditContext(raw: "Original Title", rendered: "")
        )
        let latest = makeRemotePost(
            title: PostTitleWithEditContext(raw: "Server Title", rendered: "")
        )
        var params = PostUpdateParams(meta: nil)
        params.title = "Client Title"

        #expect(params.hasConflicts(from: original, to: latest))
    }

    @Test("Conflict on content change")
    func hasFieldConflictsDetectsContentConflict() {
        let original = makeRemotePost(
            content: PostContentWithEditContext(raw: "Original content", rendered: "", protected: nil, blockVersion: nil)
        )
        let latest = makeRemotePost(
            content: PostContentWithEditContext(raw: "Server content", rendered: "", protected: nil, blockVersion: nil)
        )
        var params = PostUpdateParams(meta: nil)
        params.content = "Client content"

        #expect(params.hasConflicts(from: original, to: latest))
    }

    @Test("Conflict on categories change")
    func hasFieldConflictsDetectsCategoriesConflict() {
        let original = makeRemotePost(categories: [TermId(1), TermId(2)])
        let latest = makeRemotePost(categories: [TermId(1), TermId(3)])
        var params = PostUpdateParams(meta: nil)
        params.categories = [TermId(1), TermId(4)]

        #expect(params.hasConflicts(from: original, to: latest))
    }

    @Test("No conflict on categories when client is not changing them")
    func hasFieldConflictsIgnoresCategoriesWhenClientNotChanging() {
        let original = makeRemotePost(categories: [TermId(1), TermId(2)])
        let latest = makeRemotePost(categories: [TermId(1), TermId(3)])
        let params = PostUpdateParams(meta: nil) // categories defaults to empty

        #expect(!params.hasConflicts(from: original, to: latest))
    }

    // MARK: - changes(from:to:) Tests

    @Test("changes returns empty params when posts are identical")
    func changesReturnsEmptyForIdenticalPosts() {
        let post = makeRemotePost(slug: "same", status: .draft)
        let diff = PostUpdateParams.changes(from: post, to: post)

        #expect(diff.slug == nil)
        #expect(diff.status == nil)
        #expect(diff.title == nil)
        #expect(diff.content == nil)
        #expect(diff.categories.isEmpty)
        #expect(diff.tags.isEmpty)
    }

    @Test("changes captures only changed fields")
    func changesReturnsOnlyChangedFields() {
        let original = makeRemotePost(slug: "old-slug", status: .draft)
        let latest = makeRemotePost(slug: "new-slug", status: .draft)
        let diff = PostUpdateParams.changes(from: original, to: latest)

        #expect(diff.slug == "new-slug")
        #expect(diff.status == nil) // unchanged
    }

    @Test("changes detects title change")
    func changesDetectsTitleChange() {
        let original = makeRemotePost(
            title: PostTitleWithEditContext(raw: "Old", rendered: "")
        )
        let latest = makeRemotePost(
            title: PostTitleWithEditContext(raw: "New", rendered: "")
        )
        let diff = PostUpdateParams.changes(from: original, to: latest)

        #expect(diff.title == "New")
    }

    @Test("changes detects category change using set comparison")
    func changesDetectsCategoryChange() {
        let original = makeRemotePost(categories: [TermId(1), TermId(2)])
        let latest = makeRemotePost(categories: [TermId(2), TermId(3)])
        let diff = PostUpdateParams.changes(from: original, to: latest)

        #expect(Set(diff.categories) == Set([TermId(2), TermId(3)]))
    }

    @Test("changes ignores category order")
    func changesIgnoresCategoryOrder() {
        let original = makeRemotePost(categories: [TermId(1), TermId(2)])
        let latest = makeRemotePost(categories: [TermId(2), TermId(1)])
        let diff = PostUpdateParams.changes(from: original, to: latest)

        #expect(diff.categories.isEmpty)
    }

    // MARK: - hasConflicts(with:) Tests

    @Test("hasConflicts returns false when both params are empty")
    func hasConflictsReturnsFalseForEmptyParams() {
        let a = PostUpdateParams(meta: nil)
        let b = PostUpdateParams(meta: nil)

        #expect(!a.hasConflicts(with: b))
    }

    @Test("hasConflicts returns false when fields don't overlap")
    func hasConflictsReturnsFalseForNonOverlappingFields() {
        var a = PostUpdateParams(meta: nil)
        a.slug = "client-slug"
        var b = PostUpdateParams(meta: nil)
        b.status = .publish

        #expect(!a.hasConflicts(with: b))
    }

    @Test("hasConflicts returns true when same field has different values")
    func hasConflictsReturnsTrueForDifferentValues() {
        var a = PostUpdateParams(meta: nil)
        a.slug = "client-slug"
        var b = PostUpdateParams(meta: nil)
        b.slug = "server-slug"

        #expect(a.hasConflicts(with: b))
    }

    @Test("hasConflicts returns false when same field has same value")
    func hasConflictsReturnsFalseForSameValues() {
        var a = PostUpdateParams(meta: nil)
        a.slug = "same-slug"
        var b = PostUpdateParams(meta: nil)
        b.slug = "same-slug"

        #expect(!a.hasConflicts(with: b))
    }

    @Test("hasConflicts detects category conflict")
    func hasConflictsDetectsCategoryConflict() {
        var a = PostUpdateParams(meta: nil)
        a.categories = [TermId(1), TermId(2)]
        var b = PostUpdateParams(meta: nil)
        b.categories = [TermId(3), TermId(4)]

        #expect(a.hasConflicts(with: b))
    }

    @Test("hasConflicts ignores categories when one side is empty")
    func hasConflictsIgnoresCategoriesWhenOneSideEmpty() {
        var a = PostUpdateParams(meta: nil)
        a.categories = [TermId(1)]
        let b = PostUpdateParams(meta: nil) // categories defaults to empty

        #expect(!a.hasConflicts(with: b))
    }
}

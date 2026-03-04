import Testing
import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
@testable import WordPress
@testable import WordPressData

@MainActor
struct CustomPostEditorServiceTests {

    // MARK: - New Post Tests

    @Test("applyLocally updates PostCreateParams for new posts")
    func applyLocallyUpdatesCreateParamsForNewPost() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let service = try makeService(blog: blog, post: nil)

        var settings = service.settings
        settings.slug = "custom-slug"
        settings.excerpt = "Custom excerpt"

        // When
        service.applyLocally(settings: settings)

        // Then: the settings property should reflect the applied changes
        #expect(service.settings.slug == "custom-slug")
        #expect(service.settings.excerpt == "Custom excerpt")
        #expect(service.inspectPendingSettings() == nil) // new posts don't use pendingSettings
    }

    // MARK: - Existing Post Tests

    @Test("applyLocally stores pendingSettings for existing posts")
    func applyLocallyStoresPendingSettingsForExistingPost() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)

        var settings = service.settings
        settings.slug = "updated-slug"

        // When
        service.applyLocally(settings: settings)

        // Then
        #expect(service.inspectPendingSettings() != nil)
        #expect(service.inspectPendingSettings()?.slug == "updated-slug")
    }

    @Test("settings returns pendingSettings when set")
    func settingsReturnsPendingSettingsWhenSet() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)

        var settings = service.settings
        settings.slug = "pending-slug"

        // When
        service.applyLocally(settings: settings)

        // Then: the settings property should return the pending settings
        #expect(service.settings.slug == "pending-slug")
    }

    @Test("settings returns original settings when no pendingSettings")
    func settingsReturnsOriginalWhenNoPendingSettings() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)

        // Then: pendingSettings should be nil and settings should come from the post
        #expect(service.inspectPendingSettings() == nil)
        #expect(service.settings.slug == "test-post")
    }

    // MARK: - hasSettingsChanges Tests

    @Test("hasSettingsChanges returns false when no changes made to existing post")
    func hasSettingsChangesReturnsFalseForUnmodifiedExistingPost() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)

        #expect(service.hasSettingsChanges == false)
    }

    @Test("hasSettingsChanges returns true after applying different settings to existing post")
    func hasSettingsChangesReturnsTrueAfterApplyingSettingsToExistingPost() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)

        var settings = service.settings
        settings.slug = "changed-slug"
        service.applyLocally(settings: settings)

        #expect(service.hasSettingsChanges == true)
    }

    @Test("hasSettingsChanges returns false after reverting settings to original on existing post")
    func hasSettingsChangesReturnsFalseAfterRevertingExistingPost() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)

        let original = service.settings

        var modified = original
        modified.slug = "changed-slug"
        service.applyLocally(settings: modified)
        #expect(service.hasSettingsChanges == true)

        // Revert
        service.applyLocally(settings: original)
        #expect(service.hasSettingsChanges == false)
    }

    @Test("hasSettingsChanges returns false for unmodified new post")
    func hasSettingsChangesReturnsFalseForUnmodifiedNewPost() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let service = try makeService(blog: blog, post: nil)

        #expect(service.hasSettingsChanges == false)
    }

    @Test("hasSettingsChanges returns true after applying different settings to new post")
    func hasSettingsChangesReturnsTrueAfterApplyingSettingsToNewPost() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let service = try makeService(blog: blog, post: nil)

        var settings = service.settings
        settings.slug = "new-slug"
        service.applyLocally(settings: settings)

        #expect(service.hasSettingsChanges == true)
    }
}

// MARK: - Test Helpers

private func makeService(
    blog: Blog,
    post: AnyPostWithEditContext?
) throws -> CustomPostEditorService {
    let api = try WordPressAPI(
        urlSession: .shared,
        apiRootUrl: .parse(input: "https://example.com/wp-json"),
        authentication: .none
    )
    let client = WordPressClient(
        api: api,
        siteURL: URL(string: "https://example.com")!
    )
    let postService = PostService(noHandle: .init())

    return CustomPostEditorService(
        blog: blog,
        post: post,
        details: makePostTypeDetails(),
        client: client,
        service: postService
    )
}

private func makePostTypeDetails() -> PostTypeDetailsWithEditContext {
    PostTypeDetailsWithEditContext(
        capabilities: [:],
        description: "",
        hierarchical: false,
        viewable: true,
        labels: makePostTypeLabels(),
        name: "Test Post Type",
        slug: "test_post_type",
        supports: PostTypeSupportsMap(map: [
            .title: .bool(true),
            .editor: .bool(true),
        ]),
        hasArchive: .bool(false),
        taxonomies: [],
        restBase: "test_post_type",
        restNamespace: "wp/v2",
        visibility: PostTypeVisibility(showInNavMenus: true, showUi: true),
        icon: nil
    )
}

private func makePostTypeLabels() -> PostTypeLabels {
    PostTypeLabels(
        name: "", singularName: "", addNew: "", addNewItem: "",
        editItem: "", newItem: "", viewItem: "", viewItems: "",
        searchItems: "", notFound: "", notFoundInTrash: "",
        parentItemColon: nil, allItems: "", archives: "",
        attributes: "", insertIntoItem: "", uploadedToThisItem: "",
        featuredImage: "", setFeaturedImage: "", removeFeaturedImage: "",
        useFeaturedImage: "", filterItemsList: "", filterByDate: "",
        itemsListNavigation: "", itemsList: "", itemPublished: "",
        itemPublishedPrivately: "", itemRevertedToDraft: "",
        itemTrashed: "", itemScheduled: "", itemUpdated: "",
        itemLink: "", itemLinkDescription: "", menuName: "",
        nameAdminBar: ""
    )
}

private func makeRemotePost(
    tags: [TermId]? = nil,
    categories: [TermId]? = nil
) -> AnyPostWithEditContext {
    AnyPostWithEditContext(
        id: PostId(1),
        date: "2025-01-01T00:00:00",
        dateGmt: Date(timeIntervalSince1970: 0),
        guid: PostGuidWithEditContext(raw: nil, rendered: ""),
        link: "https://example.com",
        modified: "2025-01-01T00:00:00",
        modifiedGmt: Date(timeIntervalSince1970: 0),
        slug: "test-post",
        status: .draft,
        postType: "post",
        password: nil,
        permalinkTemplate: nil,
        generatedSlug: nil,
        title: nil,
        content: PostContentWithEditContext(raw: nil, rendered: "", protected: nil, blockVersion: nil),
        author: nil,
        excerpt: nil,
        featuredMedia: nil,
        commentStatus: .open,
        pingStatus: .open,
        format: nil,
        meta: nil,
        sticky: nil,
        template: "",
        categories: categories,
        tags: tags,
        parent: nil,
        menuOrder: nil,
        additionalFields: nil
    )
}

import Testing
import Foundation
import JetpackSocial
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress
@testable import WordPressCore
@testable import WordPressData

@MainActor
struct CustomPostEditorServiceTests {

    // MARK: - New Post Tests

    @Test("applyLocally updates settings for new posts")
    func applyLocallyUpdatesSettingsForNewPost() throws {
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

    @Test("applyLocally encodes social sharing context into create params for new posts")
    func applyLocallyEncodesSocialSharingContextIntoCreateParamsForNewPost() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let service = try makeService(blog: blog, post: nil)
        var settings = service.settings
        settings.socialSharingDraft = PostSocialSharingDraft(
            customMessage: "Share this",
            connectionsByID: [
                "1": .init(id: "1", enabled: true),
                "2": .init(id: "2", enabled: false)
            ]
        )

        // When
        service.applyLocally(settings: settings)

        // Then
        let newSettings = try #require(service.inspectNewPostSettings())
        let params = newSettings.makeCreateParameters()
        #expect(params.meta?.publicizeMessage == "Share this")

        let entries = try #require(params.additionalFields?.arrayValueForKey(key: "jetpack_publicize_connections"))
        let flagsByID = Dictionary(
            uniqueKeysWithValues: entries.compactMap { entry -> (String, Bool)? in
                guard case let .object(dict) = entry,
                    case let .string(id)? = dict["connection_id"],
                    case let .bool(enabled)? = dict["enabled"]
                else {
                    return nil
                }
                return (id, enabled)
            }
        )
        #expect(flagsByID == ["1": true, "2": false])
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

    @Test("applyLocally stores social sharing draft for existing posts")
    func applyLocallyStoresSocialSharingDraftForExistingPost() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = makeRemotePost()
        let service = try makeService(blog: blog, post: post)
        var settings = service.settings
        settings.socialSharingDraft = PostSocialSharingDraft(
            customMessage: "Share this",
            connectionsByID: [
                "1": .init(id: "1", enabled: true),
                "2": .init(id: "2", enabled: false)
            ]
        )

        // When
        service.applyLocally(settings: settings)

        // Then
        #expect(service.inspectPendingSettings()?.socialSharingDraft == settings.socialSharingDraft)
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

    @Test("hasSettingsChanges stays false after applying fetched social sharing draft")
    func hasSettingsChangesReturnsFalseAfterApplyingFetchedSocialSharingDraft() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let fetchedDraft = PostSocialSharingDraft(
            customMessage: "Stored message",
            connectionsByID: [
                "12345": .init(id: "12345", enabled: false)
            ]
        )
        let post = makeRemotePost(
            meta: PostMeta().addingPublicizeMessage("Stored message"),
            additionalFields: WpAdditionalFields()
                .addingPublicizeConnections(fetchedDraft.connectionsByID ?? [:])
        )
        let service = try makeService(blog: blog, post: post)

        var settings = service.settings
        // Mirrors the value that CustomPostSettingsViewModel receives from the
        // fetched post. Applying it locally should not dirty the editor baseline.
        settings.socialSharingDraft = fetchedDraft
        service.applyLocally(settings: settings)

        #expect(service.settings.socialSharingDraft == fetchedDraft)
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

    // MARK: - initialSettings Tests

    @Test("init with initialSettings uses provided settings instead of defaults")
    func initWithInitialSettingsUsesProvidedSettings() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()

        var settings = PostSettings()
        settings.categoryIDs = [5]

        let service = try makeService(blog: blog, post: nil, initialSettings: settings)

        #expect(service.settings.categoryIDs == [5])
        #expect(service.inspectNewPostSettings()?.categoryIDs == [5])
    }
}

// MARK: - Test Helpers

private func makeService(
    blog: Blog,
    post: AnyPostWithEditContext?,
    initialSettings: PostSettings? = nil
) throws -> CustomPostEditorService {
    let api = try WordPressAPI(
        urlSession: .shared,
        siteInfo: .selfHosted(
            siteUrl: .parse(input: "https://example.com"),
            apiRoot: .parse(input: "https://example.com/wp-json")
        ),
        authentication: .none
    )
    let client = WordPressClient(
        api: api,
        siteURL: URL(string: "https://example.com")!
    )
    let wpService = try api.createService(cache: .bootstrap())

    return CustomPostEditorService(
        blog: blog,
        post: post,
        details: makePostTypeDetails(),
        client: client,
        wpService: wpService,
        initialSettings: initialSettings
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
            .editor: .bool(true)
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
        name: "",
        singularName: "",
        addNew: "",
        addNewItem: "",
        editItem: "",
        newItem: "",
        viewItem: "",
        viewItems: "",
        searchItems: "",
        notFound: "",
        notFoundInTrash: "",
        parentItemColon: nil,
        allItems: "",
        archives: "",
        attributes: "",
        insertIntoItem: "",
        uploadedToThisItem: "",
        featuredImage: "",
        setFeaturedImage: "",
        removeFeaturedImage: "",
        useFeaturedImage: "",
        filterItemsList: "",
        filterByDate: "",
        itemsListNavigation: "",
        itemsList: "",
        itemPublished: "",
        itemPublishedPrivately: "",
        itemRevertedToDraft: "",
        itemTrashed: "",
        itemScheduled: "",
        itemUpdated: "",
        itemLink: "",
        itemLinkDescription: "",
        menuName: "",
        nameAdminBar: ""
    )
}

private func makeRemotePost(
    tags: [TermId]? = nil,
    categories: [TermId]? = nil,
    meta: PostMeta? = nil,
    additionalFields: WpAdditionalFields? = nil
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
        meta: meta,
        sticky: nil,
        template: "",
        categories: categories,
        tags: tags,
        parent: nil,
        menuOrder: nil,
        additionalFields: additionalFields
    )
}

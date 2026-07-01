import Testing
import Foundation
import JetpackSocial
import SwiftUI
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress
@testable import WordPressCore
@testable import WordPressData

@MainActor
struct CustomPostSettingsViewModelTests {

    @Test("hasChanges stays false after settings mutation when social v2 is enabled and post has disabled connections")
    func hasChangesIsFalseAfterUnrelatedSettingsMutation() throws {
        // Given: a published post whose additional_fields encode a disabled connection.
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = try makePostWithDisabledConnection()
        let editorService = try makeEditorService(blog: blog, post: post)
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        // Sanity: the parsed draft has the disabled connection from the post.
        #expect(
            viewModel.settings.socialSharingDraft?.connectionsByID == [
                "12345": .init(id: "12345", enabled: false)
            ]
        )

        // When: settings is reassigned to a value-equivalent copy (simulating
        // `resolveTermNames` writing back resolved-but-identical tags).
        viewModel.settings = viewModel.settings

        // Then: hasChanges stays false because nothing actually changed.
        #expect(!viewModel.hasChanges)
    }

    @Test("hasChanges flips to true when the user toggles a social connection")
    func hasChangesIsTrueAfterSocialDraftToggle() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = try makePostWithDisabledConnection()
        let editorService = try makeEditorService(blog: blog, post: post)
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        // When: the user toggles the disabled connection back ON.
        let binding = try #require(viewModel.v2SocialSharing?.draft)
        var draft = binding.wrappedValue
        draft.connectionsByID?["12345"] = .init(id: "12345", enabled: true)
        binding.wrappedValue = draft

        // Then: hasChanges flips to true.
        #expect(viewModel.hasChanges)
    }

    @Test("hasChanges returns to false when the user toggles back to the original state")
    func hasChangesReturnsFalseAfterToggleAndUntoggle() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = try makePostWithDisabledConnection()
        let editorService = try makeEditorService(blog: blog, post: post)
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        // When: toggle ON, then toggle back OFF.
        let binding = try #require(viewModel.v2SocialSharing?.draft)
        var draft = binding.wrappedValue
        draft.connectionsByID?["12345"] = .init(id: "12345", enabled: true)
        binding.wrappedValue = draft
        draft.connectionsByID?["12345"] = .init(id: "12345", enabled: false)
        binding.wrappedValue = draft

        // Then: PostSocialSharingDraft is structurally Equatable, so we're back
        // to the initial state.
        #expect(!viewModel.hasChanges)
    }

    @Test("new post initialization preserves locally stored social sharing draft")
    func newPostInitializationPreservesStoredSocialSharingDraft() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let storedDraft = PostSocialSharingDraft(
            customMessage: "Stored message",
            connectionsByID: [
                "12345": .init(id: "12345", enabled: false)
            ]
        )
        var initialSettings = PostSettings()
        initialSettings.socialSharingDraft = storedDraft
        let editorService = try makeEditorService(
            blog: blog,
            post: nil,
            initialSettings: initialSettings
        )
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        #expect(viewModel.settings.socialSharingDraft == storedDraft)
    }

    @Test("social v2 is hidden when the post type does not support publicize")
    func socialV2IsHiddenWhenPostTypeDoesNotSupportPublicize() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let storedDraft = PostSocialSharingDraft(
            customMessage: "Stored message",
            connectionsByID: [
                "12345": .init(id: "12345", enabled: false)
            ]
        )
        var initialSettings = PostSettings()
        initialSettings.socialSharingDraft = storedDraft
        let editorService = try makeEditorService(
            blog: blog,
            post: nil,
            initialSettings: initialSettings,
            supportsPublicize: false
        )
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        #expect(viewModel.v2SocialSharing == nil)
        #expect(viewModel.settings.socialSharingDraft == nil)
        #expect(viewModel.getSettingsToSave(for: viewModel.settings).socialSharingDraft == nil)
    }

    @Test("social v2 is hidden and stripped when the post is private")
    func socialV2IsHiddenAndStrippedWhenPostIsPrivate() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = try makePostWithDisabledConnection(status: .private)
        let editorService = try makeEditorService(blog: blog, post: post)
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        #expect(viewModel.v2SocialSharing == nil)
        #expect(viewModel.settings.socialSharingDraft == nil)
        #expect(!viewModel.hasChanges)
        #expect(viewModel.getSettingsToSave(for: viewModel.settings).socialSharingDraft == nil)
    }

    @Test("social sharing draft is stripped when settings are changed to private")
    func socialSharingDraftIsStrippedWhenSettingsBecomePrivate() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = try makePostWithDisabledConnection()
        let editorService = try makeEditorService(blog: blog, post: post)
        let connectionsService = makeConnectionsService()

        let viewModel = CustomPostSettingsViewModel(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: connectionsService
        )

        viewModel.settings.status = .publishPrivate

        #expect(viewModel.v2SocialSharing == nil)
        #expect(viewModel.getSettingsToSave(for: viewModel.settings).socialSharingDraft == nil)
    }

    // MARK: - shouldShow Jetpack rows

    @Test("shouldShow .jetpackAccessLevel is true for post type when Jetpack newsletter is available")
    func shouldShowAccessLevelTrue() throws {
        let viewModel = try makeViewModel(postTypeSlug: "post", jetpackNewsletter: true)
        #expect(viewModel.shouldShow(.jetpackAccessLevel))
    }

    @Test("shouldShow .jetpackAccessLevel is false for non-post type")
    func shouldShowAccessLevelFalseForNonPost() throws {
        let viewModel = try makeViewModel(postTypeSlug: "page", jetpackNewsletter: true)
        #expect(!viewModel.shouldShow(.jetpackAccessLevel))
    }

    @Test("shouldShow .jetpackAccessLevel is false when Jetpack newsletter is unavailable")
    func shouldShowAccessLevelFalseWithoutNewsletter() throws {
        let viewModel = try makeViewModel(postTypeSlug: "post", jetpackNewsletter: false)
        #expect(!viewModel.shouldShow(.jetpackAccessLevel))
    }

    @Test("shouldShow .jetpackNewsletterEmailOptions is true only in publishing context")
    func shouldShowNewsletterTrueOnlyInPublishing() throws {
        let publishingVM = try makeViewModel(postTypeSlug: "post", jetpackNewsletter: true, context: .publishing)
        #expect(publishingVM.shouldShow(.jetpackNewsletterEmailOptions))

        let settingsVM = try makeViewModel(postTypeSlug: "post", jetpackNewsletter: true, context: .settings)
        #expect(!settingsVM.shouldShow(.jetpackNewsletterEmailOptions))
    }

    @Test("shouldShow .jetpackNewsletterEmailOptions is false for non-post type")
    func shouldShowNewsletterFalseForNonPost() throws {
        let viewModel = try makeViewModel(postTypeSlug: "page", jetpackNewsletter: true, context: .publishing)
        #expect(!viewModel.shouldShow(.jetpackNewsletterEmailOptions))
    }
}

// MARK: - Test Helpers

private func makePostWithDisabledConnection(
    status: PostStatus = .publish,
    commentStatus: PostCommentStatus? = .open,
    pingStatus: PostPingStatus? = .open
) throws -> AnyPostWithEditContext {
    // Mirrors the real server response observed when a published post has a
    // connection that was already shared (server returns enabled: false).
    let json = #"""
        {
            "jetpack_publicize_connections": [
                {"connection_id": "12345", "enabled": false}
            ]
        }
        """#
    let additionalFields = try WpAdditionalFields.fromJsonString(json: json)
    return AnyPostWithEditContext(
        id: PostId(1),
        date: "2025-01-01T00:00:00",
        dateGmt: Date(timeIntervalSince1970: 0),
        guid: PostGuidWithEditContext(raw: nil, rendered: ""),
        link: "https://example.com",
        modified: "2025-01-01T00:00:00",
        modifiedGmt: Date(timeIntervalSince1970: 0),
        slug: "test-post",
        status: status,
        postType: "post",
        password: nil,
        permalinkTemplate: nil,
        generatedSlug: nil,
        title: nil,
        content: PostContentWithEditContext(raw: nil, rendered: "", protected: nil, blockVersion: nil),
        author: nil,
        excerpt: nil,
        featuredMedia: nil,
        commentStatus: commentStatus,
        pingStatus: pingStatus,
        format: nil,
        meta: nil,
        sticky: nil,
        template: "",
        categories: nil,
        tags: nil,
        parent: nil,
        menuOrder: nil,
        additionalFields: additionalFields
    )
}

@MainActor
private func makeEditorService(
    blog: Blog,
    post: AnyPostWithEditContext?,
    initialSettings: PostSettings? = nil,
    supportsPublicize: Bool = true
) throws -> CustomPostEditorService {
    let dependencies = try makeServiceDependencies()
    return CustomPostEditorService(
        blog: blog,
        post: post,
        details: makePostTypeDetails(supportsPublicize: supportsPublicize),
        client: dependencies.client,
        wpService: dependencies.wpService,
        initialSettings: initialSettings
    )
}

private func makeServiceDependencies() throws -> (client: WordPressClient, wpService: WpService) {
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

    return (client, wpService)
}

@MainActor
private func makeConnectionsService() -> SiteSocialConnectionsService {
    // A real instance whose `connections` stays in `.loading` for the whole
    // test — sufficient for the regression check, which doesn't depend on
    // any populated data.
    let client = WPComApiClient(
        urlSession: .shared,
        authentication: .none
    )
    return SiteSocialConnectionsService(
        client: client,
        siteId: 1,
        canMarkAsShared: false
    )
}

@MainActor
private func makeViewModel(
    postTypeSlug: String,
    jetpackNewsletter: Bool,
    context: PostSettingsContext = .settings
) throws -> CustomPostSettingsViewModel {
    let coreData = ContextManager.forTesting().mainContext
    let builder = BlogBuilder(coreData)
    let blog: Blog
    if jetpackNewsletter {
        blog = builder.withAnAccount().with(modules: ["subscriptions"]).build()
    } else {
        blog = builder.withAnAccount().build()
    }
    try coreData.save()
    let post = try makePostWithDisabledConnection()
    let details = makePostTypeDetails(supportsPublicize: true, slug: postTypeSlug)
    let dependencies = try makeServiceDependencies()
    let editorService = CustomPostEditorService(
        blog: blog,
        post: post,
        details: details,
        client: dependencies.client,
        wpService: dependencies.wpService,
        initialSettings: nil
    )
    return CustomPostSettingsViewModel(
        editorService: editorService,
        blog: blog,
        socialConnectionsService: nil,
        context: context
    )
}

private func makePostTypeDetails(
    supportsPublicize: Bool = true,
    slug: String = "test_post_type"
) -> PostTypeDetailsWithEditContext {
    var supports: [PostTypeSupports: JsonValue] = [
        .title: .bool(true),
        .editor: .bool(true)
    ]
    if supportsPublicize {
        supports[.custom("publicize")] = .bool(true)
    }

    return PostTypeDetailsWithEditContext(
        capabilities: [:],
        description: "",
        hierarchical: false,
        viewable: true,
        labels: makePostTypeLabels(),
        name: "Test Post Type",
        slug: slug,
        supports: PostTypeSupportsMap(map: supports),
        hasArchive: .bool(false),
        taxonomies: [],
        restBase: slug,
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

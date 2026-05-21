import Foundation
import JetpackSocial
import SwiftUI
import WordPressAPI
import WordPressData
import WordPressKit
import WordPressCore
import WordPressShared
import WordPressAPIInternal
import Combine

/// Post settings view model for REST API–backed custom post types (`CustomPostEditorService`).
@MainActor
final class CustomPostSettingsViewModel: NSObject, ObservableObject, PostSettingsViewModelProtocol {
    private let editorService: CustomPostEditorService
    private var wpService: WpService {
        editorService.wpService
    }

    let blog: Blog
    let capabilities: PostSettingsCapabilities
    let isStandalone: Bool
    let context: PostSettingsContext
    let featuredImageViewModel: PostSettingsFeaturedImageViewModel?
    let client: WordPressClient?

    @Published var settings: PostSettings {
        didSet {
            refresh(from: oldValue, to: settings)
        }
    }

    @Published var isSaving = false
    @Published var hasChanges = false
    @Published var displayedCategories: [String] = []
    @Published var displayedTags: [String] = []
    @Published var isResolvingTags = false
    @Published var isResolvingCustomTerms = false
    @Published var suggestedTags: [String] = []
    @Published var customTaxonomies: [SiteTaxonomy] = []
    @Published var parentPageText: String?
    @Published var socialSharingState: PostSettingsSocialSharingSectionState?
    @Published var isShowingDeletedAlert = false
    private let socialConnectionsService: SiteSocialConnectionsService?

    /// Strong reference that keeps `AddConnectionCoordinator` alive while
    /// the OAuth flow is in progress. Cleared when the user starts a new
    /// add flow or when this view model is deallocated. Mirrors the same
    /// lifetime pattern in `ManageConnectionsHostingController`.
    private var addConnectionCoordinator: AddConnectionCoordinator?

    private let originalSettings: PostSettings
    private let preferences: UserPersistentRepository
    private var cancellables = Set<AnyCancellable>()

    var onDismiss: (() -> Void)?
    var onEditorPostSaved: (() -> Void)?
    var onPostPublished: (() -> Void)?
    weak var viewController: UIViewController?

    // MARK: - Computed Properties

    /// The content of the post, used for AI excerpt generation.
    var postContent: String {
        editorService.post?.content.raw ?? ""
    }

    var navigationTitle: String {
        String.localizedStringWithFormat(
            PostSettingsStrings.customPostSettingsTitle,
            editorService.details.name
        )
    }

    var deletedAlertTitle: String {
        isPost ? PostSettingsStrings.postDeletedTitle : PostSettingsStrings.pageDeletedTitle
    }

    var deletedAlertMessage: String {
        isPost ? PostSettingsStrings.postDeletedMessage : PostSettingsStrings.pageDeletedMessage
    }

    var isScheduled: Bool {
        editorService.post?.status == .future
    }

    var authorDisplayName: String {
        settings.author?.displayName ?? ""
    }

    var authorAvatarURL: URL? {
        settings.author?.avatarURL
    }

    var emailToSubscribers: Bool {
        get { !settings.metadata.isJetpackNewsletterEmailDisabled }
        set { settings.metadata.isJetpackNewsletterEmailDisabled = !newValue }
    }

    var accessLevel: JetpackPostAccessLevel {
        get { settings.metadata.accessLevel ?? .everybody }
        set { settings.metadata.accessLevel = newValue }
    }

    var publishDateText: String? {
        guard let date = settings.publishDate else {
            return nil
        }
        return PostSettingsDateFormatter.formattedDate(date, in: timeZone)
    }

    var visibilityText: String {
        PostVisibility(status: settings.status, password: settings.password)
            .localizedTitle
    }

    var slugText: String {
        settings.slug.isEmpty ? (suggestedSlug ?? "") : settings.slug
    }

    var suggestedSlug: String? {
        editorService.post?.generatedSlug
    }

    var permalinkTemplate: String? {
        editorService.post?.permalinkTemplate
    }

    var postFormatText: String {
        guard capabilities.supportsPostFormats else { return "" }
        return blog.postFormatText(fromSlug: settings.postFormat)
            ?? NSLocalizedString("Standard", comment: "Default post format")
    }

    var timeZone: TimeZone {
        blog.timeZone ?? TimeZone.current
    }

    var isDraftOrPending: Bool {
        if let post = editorService.post {
            return post.status == .draft || post.status == .pending
        }
        return true
    }

    var isPost: Bool {
        editorService.details.slug == "post"
    }

    var shouldShowStickyOption: Bool {
        // Sticky is exclusively a WordPress "post" type feature
        guard isPost else { return false }
        // Show sticky option if blog supports WPComRESTAPI OR user is admin
        return blog.supports(.wpComRESTAPI) || blog.isAdmin
    }

    var lastEditedText: String? {
        editorService.post?.modifiedGmt.toMediumString()
    }

    var postID: Int? {
        guard let id = editorService.post?.id else { return nil }
        return id > 0 ? Int(id) : nil
    }

    func parentPagePickerDestination() -> CustomPostParentPagePicker? {
        guard editorService.details.hierarchical else {
            return nil
        }
        return CustomPostParentPagePicker(
            client: editorService.client,
            service: wpService,
            details: editorService.details,
            blog: blog,
            currentPostID: postID,
            currentParentID: settings.parentPageID,
            onSelection: { [weak self] selectedParentID in
                self?.settings.parentPageID = selectedParentID
            }
        )
    }

    /// Whether the post has a remote representation (used for permalink preview).
    var hasRemote: Bool {
        editorService.post != nil
    }

    var publishButtonTitle: String {
        let isScheduled = settings.publishDate.map { $0 > .now } ?? false
        return isScheduled ? PrepublishingSheetStrings.schedule : PrepublishingSheetStrings.publish
    }

    // MARK: - Initializer

    /// Designated init exposed to tests so they can inject a stubbed
    /// `SiteSocialConnectionsService` without going through `JetpackSocialFactory.shared`.
    init(
        editorService: CustomPostEditorService,
        blog: Blog,
        socialConnectionsService: SiteSocialConnectionsService?,
        isStandalone: Bool = false,
        context: PostSettingsContext = .settings,
        preferences: UserPersistentRepository = UserDefaults.standard
    ) {
        self.editorService = editorService
        self.blog = blog
        self.isStandalone = isStandalone
        self.context = context
        self.preferences = preferences
        self.client = editorService.client
        let capabilities = PostSettingsCapabilities(from: editorService.details)
        self.capabilities = capabilities
        let socialConnectionsService = capabilities.supportsPublicize ? socialConnectionsService : nil
        self.socialConnectionsService = socialConnectionsService

        var initialSettings = editorService.settings
        // Resolve author display name from Blog's cached authors
        if let authorId = initialSettings.author?.id,
            let authors = blog.authors,
            let author = authors.first(where: { $0.userID.intValue == authorId })
        {
            initialSettings.author = PostSettings.Author(
                id: authorId,
                displayName: author.displayName ?? "–",
                avatarURL: author.avatarURL.flatMap(URL.init)
            )
        }

        if socialConnectionsService != nil, initialSettings.status != .publishPrivate {
            if editorService.post == nil, initialSettings.socialSharingDraft == nil {
                // Note: After PR 25543 is merged, keep this nil guard. New
                // posts can already carry a draft on editorService.settings.
                initialSettings.socialSharingDraft = PostSocialSharingDraft()
            }
        } else {
            initialSettings.socialSharingDraft = nil
        }

        self.settings = initialSettings
        self.originalSettings = initialSettings

        let featuredImageViewModel: PostSettingsFeaturedImageViewModel?
        if capabilities.supportsFeaturedImage {
            let featuredImage = initialSettings.featuredImageID.flatMap {
                Media.existingOrStubMediaWith(
                    mediaID: NSNumber(value: $0),
                    inBlog: blog
                )
            }
            featuredImageViewModel = PostSettingsFeaturedImageViewModel(
                blog: blog,
                featuredImage: featuredImage
            )
        } else {
            featuredImageViewModel = nil
        }
        self.featuredImageViewModel = featuredImageViewModel

        super.init()

        featuredImageViewModel?.$selection.dropFirst()
            .sink { [weak self] media in
                self?.settings.featuredImageID = media?.mediaID?.intValue
            }
            .store(in: &cancellables)

        WPAnalytics.track(.postSettingsShown)

        refreshDisplayedCategories()
        refreshDisplayedTags()
        refreshCustomTaxonomies()
        refreshParentPageText()
        resolveTermNames()
    }

    convenience init(
        editorService: CustomPostEditorService,
        blog: Blog,
        isStandalone: Bool = false,
        context: PostSettingsContext = .settings,
        preferences: UserPersistentRepository = UserDefaults.standard
    ) {
        self.init(
            editorService: editorService,
            blog: blog,
            socialConnectionsService: Self.resolveSocialConnectionsService(blog: blog, details: editorService.details),
            isStandalone: isStandalone,
            context: context,
            preferences: preferences
        )
    }

    // MARK: - Actions

    func onAppear() {}

    func shouldShow(_ row: PostSettingsRow) -> Bool {
        switch row {
        case .jetpackAccessLevel:
            return isPost && blog.supports(.jetpackNewsletter)
        case .jetpackNewsletterEmailOptions:
            return isPost && blog.supports(.jetpackNewsletter) && context == .publishing
        }
    }

    func buttonCancelTapped() {
        onDismiss?()
    }

    func buttonSaveTapped() {
        guard isStandalone else {
            let settingsToSave = getSettingsToSave(for: settings)
            editorService.applyLocally(settings: settingsToSave)
            didSaveChanges()
            onEditorPostSaved?()
            onDismiss?()
            return
        }

        isSaving = true
        Task {
            do {
                let settingsToSave = getSettingsToSave(for: settings)
                try await editorService.save(settings: settingsToSave, publish: false)
                didSaveChanges()
                onEditorPostSaved?()
                onDismiss?()
            } catch {
                isSaving = false
                Notice(error: error, title: PostSettingsStrings.saveFailedMessage).post()
            }
        }
    }

    func buttonPublishTapped() {
        isSaving = true
        Task {
            do {
                try await editorService.save(settings: settings, publish: true)
                onPostPublished?()
                onDismiss?()
            } catch {
                isSaving = false
                Notice(error: error, title: PostSettingsStrings.saveFailedMessage).post()
            }
        }
    }

    func getSettingsToSave(for settings: PostSettings) -> PostSettings {
        var settings = settings
        if !capabilities.supportsPublicize || settings.status == .publishPrivate {
            settings.socialSharingDraft = nil
        }
        if context == .publishing {
            // We don't support saving these changes on the "Publishing" sheet
            // as it would trigger the change in status and publishing. We'll
            // only save what we can without publishing: tags, categories, etc.
            settings.status = originalSettings.status
            settings.password = originalSettings.password
            settings.publishDate = originalSettings.publishDate
        }
        return settings
    }

    func updateVisibility(_ selection: PostVisibilityPicker.Selection) {
        track(.editorPostVisibilityChanged)

        switch selection.type {
        case .public, .protected:
            if isScheduled {
                break
            }
            settings.status = .publish
        case .private:
            settings.status = .publishPrivate
        }
        settings.password = selection.password.isEmpty ? nil : selection.password
    }

    func didSelectSuggestedTag(_ tag: String) {
        suggestedTags.removeAll(where: { $0 == tag })
        settings.tags.append(PostSettings.Term(id: 0, name: tag))
        track(.intelligenceSuggestedTagSelected)
    }

    func didSelectTags(_ tags: [TagsViewModel.SelectedTerm]) {
        settings.tags = tags.map { PostSettings.Term(id: $0.id, name: $0.name) }
    }

    func didSelectTerms(_ terms: [TagsViewModel.SelectedTerm], forTaxonomySlug taxonomySlug: String) {
        settings.otherTerms[taxonomySlug] = terms.map { PostSettings.Term(id: $0.id, name: $0.name) }
    }

    func showCategoriesPicker() {
        let categoriesVC = PostSettingsCategoriesPickerViewController(
            blog: blog,
            selectedCategoryIDs: settings.categoryIDs
        ) { [weak self] newSelectedIDs in
            self?.settings.categoryIDs = newSelectedIDs
        }
        viewController?.navigationController?.pushViewController(categoriesVC, animated: true)
    }

    func showSocialSharingOptions() {}

    var v2SocialSharing: V2SocialSharingBinding? {
        guard let service = socialConnectionsService,
            settings.status != .publishPrivate
        else {
            return nil
        }
        let binding = Binding<PostSocialSharingDraft>(
            get: { self.settings.socialSharingDraft ?? PostSocialSharingDraft() },
            set: { self.settings.socialSharingDraft = $0 }
        )
        return V2SocialSharingBinding(
            connections: service,
            draft: binding,
            isPostPublished: editorService.post?.status == .publish,
            onAddConnection: { [weak self] in
                self?.presentAddSocialConnection()
            }
        )
    }

    private func presentAddSocialConnection() {
        guard let service = socialConnectionsService,
            let presenter = viewController
        else {
            return
        }
        let coordinator = AddConnectionCoordinator(
            connectionsService: service,
            authenticator: BlogSocialOAuthAuthenticator(blog: blog),
            presenter: presenter,
            onConnectionCreated: { [weak self, weak service] connection in
                guard let self else { return }
                var draft = self.settings.socialSharingDraft ?? PostSocialSharingDraft()
                draft.addConnection(
                    connection,
                    availableConnections: service?.connections.value ?? [connection]
                )
                self.settings.socialSharingDraft = draft
            }
        )
        addConnectionCoordinator = coordinator
        coordinator.start()
    }

    // MARK: - Term Resolution

    private func resolveTermNames() {
        isResolvingTags = true
        isResolvingCustomTerms = !settings.otherTerms.isEmpty

        Task { [weak self] in
            guard let self else { return }

            do {
                let tagsService = AnyTermService(client: editorService.client, endpoint: .tags)
                let resolvedTags = try await TermResolutionService(taxonomyService: tagsService)
                    .resolveNames(for: settings.tags)
                self.settings.tags = resolvedTags
                self.refreshDisplayedTags()
                self.isResolvingTags = false

                for taxonomy in editorService.taxonomies {
                    guard let slugTerms = self.settings.otherTerms[taxonomy.slug] else { continue }
                    let termService = AnyTermService(client: editorService.client, endpoint: taxonomy.endpoint)
                    let resolved = try await TermResolutionService(taxonomyService: termService)
                        .resolveNames(for: slugTerms)
                    self.settings.otherTerms[taxonomy.slug] = resolved
                }
                self.isResolvingCustomTerms = false
            } catch {
                // TODO: We need better error handling
                Loggers.app.log(level: .error, "Failed to resolve taxonomy terms: \(error)")
            }
        }
    }

    // MARK: - Refresh

    private func refresh(from old: PostSettings, to new: PostSettings) {
        hasChanges = getSettingsToSave(for: new) != originalSettings

        if old.categoryIDs != new.categoryIDs {
            refreshDisplayedCategories()
        }
        if old.tags != new.tags {
            refreshDisplayedTags()
        }
        if old.parentPageID != new.parentPageID {
            refreshParentPageText()
        }
    }

    private func refreshDisplayedCategories() {
        displayedCategories = settings.getCategoryNames(for: blog)
    }

    private func refreshDisplayedTags() {
        displayedTags = settings.tags.map(\.name)
    }

    private func refreshParentPageText() {
        guard let parentPageID = settings.parentPageID, parentPageID != 0 else {
            parentPageText = nil
            return
        }

        parentPageText = "(ID: \(parentPageID))"

        Task { [weak self] in
            guard let self else { return }
            do {
                let post = try await editorService.client.api.posts
                    .filterRetrieveWithEditContext(
                        postEndpointType: editorService.details.toPostEndpointType(),
                        postId: PostId(Int64(parentPageID)),
                        params: .init(),
                        fields: [.title]
                    )
                    .data
                if self.settings.parentPageID == parentPageID {
                    self.parentPageText = post.title?.raw ?? "(ID: \(parentPageID))"
                }
            } catch {
                Loggers.app.log(level: .error, "Failed to resolve parent page title: \(error)")
            }
        }
    }

    private func refreshCustomTaxonomies() {
        customTaxonomies = editorService.taxonomies
    }

    // MARK: - Analytics

    private func didSaveChanges() {
        trackChanges(from: originalSettings, to: settings)
    }

    private func trackChanges(from old: PostSettings, to new: PostSettings) {
        if old.author?.id != new.author?.id {
            track(.editorPostAuthorChanged)
        }
        if old.publishDate != new.publishDate {
            track(.editorPostScheduledChanged)
        }
        if old.tags != new.tags {
            track(.editorPostTagsChanged)
        }
        if old.postFormat != new.postFormat {
            track(.editorPostFormatChanged)
        }
        if old.categoryIDs != new.categoryIDs {
            track(.editorPostCategoryChanged)
        }
        if old.featuredImageID != new.featuredImageID {
            let action = new.featuredImageID == nil ? "removed" : "changed"
            track(.editorPostFeaturedImageChanged, properties: ["action": action])
        }
        if old.excerpt != new.excerpt {
            track(.editorPostExcerptChanged)
        }
        if old.slug != new.slug {
            track(.editorPostSlugChanged)
        }
        if old.status != new.status {
            if (old.status == .pending) != (new.status == .pending) {
                track(.editorPostPendingReviewChanged)
            }
        }
        if old.isStickyPost != new.isStickyPost {
            track(.editorPostStickyChanged)
        }
        if old.parentPageID != new.parentPageID {
            track(.editorPostParentPageChanged)
        }
        if old.otherTerms != new.otherTerms {
            track(.editorPostCustomTaxonomyChanged)
        }
        if old.metadata.isJetpackNewsletterEmailDisabled != new.metadata.isJetpackNewsletterEmailDisabled {
            track(.editorPostNewsletterEmailToggled)
        }
    }

    private func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any] = [:]) {
        var properties = properties
        properties["via"] = source
        WPAnalytics.track(event, properties: properties)
    }

    private var source: String {
        switch context {
        case .settings: "post_settings"
        case .publishing: "pre_publishing"
        }
    }

    private static func resolveSocialConnectionsService(
        blog: Blog,
        details: PostTypeDetailsWithEditContext
    ) -> SiteSocialConnectionsService? {
        guard PostSettingsCapabilities(from: details).supportsPublicize,
            FeatureFlag.socialSharingV2.enabled,
            blog.supports(.publicize),
            let service = JetpackSocialFactory.shared.connectionsService(for: blog)
        else {
            return nil
        }
        return service
    }
}

import Foundation
import BuildSettingsKit
import SwiftUI
import WordPressAPI
import WordPressData
import WordPressKit
import WordPressCore
import WordPressShared
import WordPressAPIInternal
import Combine

@MainActor
final class PostSettingsViewModel: NSObject, ObservableObject {
    let blog: Blog
    let capabilities: PostSettingsCapabilities
    let isStandalone: Bool
    let context: Context
    let featuredImageViewModel: PostSettingsFeaturedImageViewModel?
    let client: WordPressClient?
    let editorContent: EditorContent?
    let editorService: CustomPostEditorService?

    struct EditorContent {
        let title: String
        let content: String
    }

    private var details: PostDetails

    private var abstractPost: AbstractPost? {
        if case .abstractPost(let post) = details { return post }
        return nil
    }

    var remotePost: AnyPostWithEditContext? {
        if case .remotePost(let post, _) = details { return post }
        return nil
    }

    private var postTypeDetails: PostTypeDetailsWithEditContext? {
        if case .remotePost(_, let details) = details { return details }
        return nil
    }

    @Published var settings: PostSettings {
        didSet {
            refresh(from: oldValue, to: settings)
        }
    }

    @Published private(set) var isSaving = false
    @Published private(set) var hasChanges = false
    @Published private(set) var displayedCategories: [String] = []
    @Published private(set) var displayedTags: [String] = []
    @Published private(set) var suggestedTags: [String] = []
    @Published private(set) var customTaxonomies: [SiteTaxonomy] = []
    @Published private(set) var parentPageText: String?
    @Published private(set) var socialSharingState: SocialSharingSectionState?

    @Published var isShowingDeletedAlert = false

    /// The content of the post, used for AI excerpt generation.
    var postContent: String {
        switch details {
        case .abstractPost(let post):
            return post.content ?? ""
        case .remotePost(let post, _):
            return post.content.raw ?? ""
        }
    }

    var navigationTitle: String {
        if let postTypeDetails {
            return String.localizedStringWithFormat(
                Strings.customPostSettingsTitle,
                postTypeDetails.name
            )
        }
        return isPost ? Strings.postSettingsTitle : Strings.pageSettingsTitle
    }

    var deletedAlertTitle: String {
        isPost ? Strings.postDeletedTitle : Strings.pageDeletedTitle
    }

    var deletedAlertMessage: String {
        isPost ? Strings.postDeletedMessage : Strings.pageDeletedMessage
    }

    var authorDisplayName: String {
        switch details {
        case .abstractPost(let post):
            return settings.author?.displayName ?? post.author?.makePlainText() ?? ""
        case .remotePost:
            return settings.author?.displayName ?? ""
        }
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
        return Self.formattedDate(date, in: timeZone)
    }

    static func formattedDate(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    var visibilityText: String {
        PostVisibility(status: settings.status, password: settings.password)
            .localizedTitle
    }

    var slugText: String {
        settings.slug.isEmpty ? (suggestedSlug ?? "") : settings.slug
    }

    var suggestedSlug: String? {
        switch details {
        case .abstractPost(let post):
            return post.suggested_slug
        case .remotePost(let post, _):
            return post.generatedSlug
        }
    }

    var permalinkTemplate: String? {
        switch details {
        case .abstractPost(let post):
            return post.permalinkTemplateURL
        case .remotePost(let post, _):
            return post.permalinkTemplate
        }
    }

    var postFormatText: String {
        guard capabilities.supportsPostFormats else { return "" }
        return blog.postFormatText(fromSlug: settings.postFormat) ?? NSLocalizedString("Standard", comment: "Default post format")
    }

    var timeZone: TimeZone {
        blog.timeZone ?? TimeZone.current
    }

    var isDraftOrPending: Bool {
        switch details {
        case .abstractPost(let post):
            return post.getOriginal().isStatus(in: [.draft, .pending])
        case .remotePost(let post, _):
            return post.status == .draft || post.status == .pending
        }
    }

    var isPost: Bool {
        switch details {
        case .abstractPost(let post):
            return post is Post
        case .remotePost(_, let typeDetails):
            return typeDetails.slug == "post"
        }
    }

    var shouldShowStickyOption: Bool {
        // Sticky is exclusively a WordPress "post" type feature
        guard isPost else { return false }
        // Show sticky option if blog supports WPComRESTAPI OR user is admin
        return blog.supports(.wpComRESTAPI) || blog.isAdmin
    }

    var lastEditedText: String? {
        switch details {
        case .abstractPost(let post):
            guard let date = post.dateModified ?? post.dateCreated else {
                return nil
            }
            return date.toMediumString()
        case .remotePost(let post, _):
            return post.modifiedGmt.toMediumString()
        }
    }

    var postID: Int? {
        switch details {
        case .abstractPost(let post):
            guard let postID = post.postID?.intValue, postID > 0 else {
                return nil
            }
            return postID
        case .remotePost(let post, _):
            let id = Int(post.id)
            return id > 0 ? id : nil
        }
    }

    /// The underlying Page, if this is a Core Data-backed page.
    var page: Page? {
        abstractPost as? Page
    }

    /// Whether the post has a remote representation (used for permalink preview).
    var hasRemote: Bool {
        switch details {
        case .abstractPost(let post):
            return post.hasRemote()
        case .remotePost:
            return true
        }
    }

    enum SocialSharingSectionState {
        /// The initial prompt to set up connections.
        case setup(JetpackSocialNoConnectionViewModel)
        /// The site has existing connections.
        case connected
    }

    enum Row {
        case jetpackAccessLevel
        case jetpackNewsletterEmailOptions
    }

    private let originalSettings: PostSettings
    private let preferences: UserPersistentRepository
    private var isSuggestedTagsRefreshNeeded = true
    private var cancellables = Set<AnyCancellable>()

    var onDismiss: (() -> Void)?
    var onEditorPostSaved: (() -> Void)?
    var onPostPublished: (() -> Void)?

    /// Weak reference to the view controller for navigation.
    /// This is temporary until we can fully migrate to SwiftUI navigation.
    weak var viewController: UIViewController?

    enum Context {
        case settings
        case publishing
    }

    // MARK: - AbstractPost Initializer

    init(
        post: AbstractPost,
        isStandalone: Bool = false,
        context: Context = .settings,
        preferences: UserPersistentRepository = UserDefaults.standard
    ) {
        self.details = .abstractPost(post)
        self.blog = post.blog
        self.capabilities = post is Post ? .post() : .page()
        self.isStandalone = isStandalone
        self.context = context
        self.preferences = preferences
        self.client = try? WordPressClientFactory.shared.instance(for: .init(blog: post.blog))
        self.editorContent = nil
        self.editorService = nil

        // Initialize settings from the post
        let initialSettings = PostSettings(from: post)
        self.settings = initialSettings
        self.originalSettings = initialSettings

        // Initialize featured image view model
        self.featuredImageViewModel = PostSettingsFeaturedImageViewModel(post: post)

        super.init()

        // Observe selection changes from featured image view model
        featuredImageViewModel?.$selection.dropFirst().sink { [weak self] media in
            self?.settings.featuredImageID = media?.mediaID?.intValue
        }.store(in: &cancellables)

        // Initialize all cached properties
        refreshDisplayedCategories()
        refreshDisplayedTags()
        refreshCustomTaxonomies()
        refreshParentPageText()
        refreshSocialSharingState()

        WPAnalytics.track(.postSettingsShown)
    }

    // MARK: - AnyPostWithEditContext Initializer

    init(
        editorService: CustomPostEditorService,
        blog: Blog,
        context: Context = .settings,
        editorContent: EditorContent? = nil
    ) {
        let post = editorService.post
        let details = editorService.details
        self.details = .remotePost(post, details)
        self.blog = blog
        self.capabilities = PostSettingsCapabilities(from: details)
        self.isStandalone = false
        self.context = context
        self.preferences = UserDefaults.standard
        self.client = editorService.client
        self.editorContent = editorContent
        self.editorService = editorService

        // Initialize settings from the remote post
        let initialSettings = PostSettings(from: post)
        self.settings = initialSettings
        self.originalSettings = initialSettings

        // Featured image is not supported for custom post types yet
        self.featuredImageViewModel = nil

        super.init()

        // Resolve author display name from Blog's cached authors
        resolveAuthorDisplayName()

        // Initialize cached properties
        refreshDisplayedCategories()
        refreshDisplayedTags()
        refreshCustomTaxonomiesForRemotePost(details: details)

        WPAnalytics.track(.postSettingsShown)
    }

    func onAppear() {
        refreshSuggestedTags()
    }

    func shouldShow(_ row: Row) -> Bool {
        // FIXME: meta support missing in AnyPostWithEditContext
        guard case .abstractPost = details else { return false }
        switch row {
        case .jetpackAccessLevel:
            return blog.supports(.wpComRESTAPI)
        case .jetpackNewsletterEmailOptions:
            return blog.supports(.wpComRESTAPI) && context == .publishing
        }
    }

    private func resolveAuthorDisplayName() {
        guard let authorId = settings.author?.id else { return }
        // Try to resolve from Blog's cached authors
        if let authors = blog.authors,
           let author = authors.first(where: { $0.userID.intValue == authorId }) {
            settings.author = PostSettings.Author(
                id: authorId,
                displayName: author.displayName ?? "–",
                avatarURL: author.avatarURL.flatMap(URL.init)
            )
        }
    }

    private func refreshSuggestedTags() {
        guard let abstractPost, isSuggestedTagsRefreshNeeded else {
            return
        }
        isSuggestedTagsRefreshNeeded = false

        let task = Task { @MainActor [weak self] in
            do {
                let tags = try await TagSuggestionsService().getSuggestedTags(for: abstractPost)
                guard let self else { return }
                if !tags.isEmpty {
                    withAnimation {
                        self.suggestedTags = tags
                    }
                }
                self.track(.intelligenceSuggestedTagsGenerated, properties: ["count": tags.count])
            } catch {
                guard let self else { return }
                self.track(.intelligenceGenerationFailed, properties: ["description": (error as NSError).debugDescription])
            }
        }
        cancellables.insert(AnyCancellable {
            task.cancel()
        })
    }

    private func refreshCustomTaxonomies() {
        guard let abstractPost else { return }

        let postType: String? = switch abstractPost {
        case is Post: "post"
        case is Page: "page"
        default: nil
        }
        guard let postType else { return }

        let customTaxonomies = try? blog.taxonomies
            .filter {
                $0.slug != "post_tag" && $0.slug != "category" && $0.supportedPostTypes.contains(postType)
            }
            .sorted(using: KeyPathComparator(\.name))
        self.customTaxonomies = customTaxonomies ?? []
    }

    private func refreshCustomTaxonomiesForRemotePost(details: PostTypeDetailsWithEditContext) {
        let customSlugs = capabilities.customTaxonomySlugs
        guard !customSlugs.isEmpty else { return }

        let customTaxonomies = try? blog.taxonomies
            .filter { customSlugs.contains($0.slug) }
            .sorted(using: KeyPathComparator(\.name))
        self.customTaxonomies = customTaxonomies ?? []
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
        switch details {
        case .abstractPost(let post):
            displayedCategories = settings.getCategoryNames(for: post)
        case .remotePost:
            displayedCategories = settings.getCategoryNames(for: blog)
        }
    }

    private func refreshDisplayedTags() {
        displayedTags = AbstractPost.makeTags(from: settings.tags)
    }

    private func refreshParentPageText() {
        if let page,
           let context = page.managedObjectContext,
           let parentPageID = settings.parentPageID {
            parentPageText = Page.parentPageText(in: context, parentID: NSNumber(value: parentPageID))
        } else {
            parentPageText = nil
        }
    }

    // MARK: - Actions

    func buttonCancelTapped() {
        onDismiss?()
    }

    func buttonSaveTapped() {
        switch details {
        case .abstractPost(let post):
            buttonSaveTappedForAbstractPost(post)
        case .remotePost:
            buttonSaveTappedForRemotePost()
        }
    }

    private func buttonSaveTappedForAbstractPost(_ post: AbstractPost) {
        // Check if the post still exists
        guard let context = post.managedObjectContext,
              let _ = try? context.existingObject(with: post.objectID) else {
            isShowingDeletedAlert = true
            return
        }

        guard isStandalone else {
            // Apply settings and return to the editor (editor-specific)
            settings.apply(to: post)
            didSaveChanges()
            wpAssert(onEditorPostSaved != nil, "configuration missing")
            onEditorPostSaved?()
            onDismiss?()
            return
        }

        isSaving = true
        Task {
            await actuallySaveAbstractPost(post)
        }
    }

    private func buttonSaveTappedForRemotePost() {
        isSaving = true
        Task {
            await saveRemotePost()
        }
    }

    private func actuallySaveAbstractPost(_ post: AbstractPost) async {
        do {
            let settings = getSettingsToSave(for: self.settings)
            let coordinator = PostCoordinator.shared
            if coordinator.isSyncAllowed(for: post) && post.status == settings.status {
                let revision = post.createRevision()
                settings.apply(to: revision)
                coordinator.setNeedsSync(for: revision)
            } else {
                // When sync is not allowed, use the changes parameter
                let changes = settings.makeUpdateParameters(from: post)
                try await coordinator.save(post, changes: changes)
            }
            didSaveChanges()
            onDismiss?()
        } catch {
            isSaving = false
            // `PostCoordinator` handles errors by showing an alert when needed
        }
    }

    private func saveRemotePost() async {
        guard let editorService else {
            wpAssertionFailure("missing remote post context")
            isSaving = false
            return
        }

        do {
            let params = settings.makeUpdateParameters(from: editorService.post)
            try await editorService.update(params: params)
            if case .remotePost(_, let typeDetails) = self.details {
                self.details = .remotePost(editorService.post, typeDetails)
            }

            didSaveChanges()
            onEditorPostSaved?()
            onDismiss?()
        } catch {
            isSaving = false
            Notice(error: error, title: Strings.saveFailedMessage).post()
        }
    }

    func getSettingsToSave(for settings: PostSettings) -> PostSettings {
        var settings = settings
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

    func buttonPublishTapped() {
        switch details {
        case .abstractPost(let post):
            publishAbstractPost(post)
        case .remotePost:
            publishRemotePost()
        }
    }

    private func publishAbstractPost(_ post: AbstractPost) {
        // Check if the post still exists
        guard let context = post.managedObjectContext,
              let _ = try? context.existingObject(with: post.objectID) else {
            isShowingDeletedAlert = true
            return
        }

        isSaving = true
        Task {
            do {
                let coordinator = PostCoordinator.shared
                let changes = settings.makeUpdateParameters(from: post)
                try await coordinator.publish(post.getOriginal(), parameters: changes)
                onPostPublished?()
            } catch {
                isSaving = false
                // `PostCoordinator` handles errors by showing an alert when needed
            }
        }
    }

    private func publishRemotePost() {
        guard let editorService else {
            wpAssertionFailure("missing remote post context")
            return
        }

        isSaving = true
        Task {
            do {
                let settingsParams = settings.makeUpdateParameters(from: editorService.post)

                let hasTitle = editorService.details.supports.map[.title] == .bool(true)
                // TODO: Change `PostUpdateParams` properties to var, so that we don't need to manually copy.
                let params = PostUpdateParams(
                    slug: settingsParams.slug,
                    status: .publish,
                    password: settingsParams.password,
                    title: hasTitle ? editorContent?.title : nil,
                    content: editorContent?.content,
                    author: settingsParams.author,
                    excerpt: settingsParams.excerpt,
                    featuredMedia: settingsParams.featuredMedia,
                    commentStatus: settingsParams.commentStatus,
                    pingStatus: settingsParams.pingStatus,
                    format: settingsParams.format,
                    meta: settingsParams.meta,
                    sticky: settingsParams.sticky,
                    categories: settingsParams.categories,
                    tags: settingsParams.tags,
                    parent: settingsParams.parent
                )

                try await editorService.update(params: params)

                if case .remotePost(_, let typeDetails) = self.details {
                    self.details = .remotePost(editorService.post, typeDetails)
                }

                onPostPublished?()
            } catch {
                isSaving = false
                Notice(error: error, title: Strings.saveFailedMessage).post()
            }
        }
    }

    private func didSaveChanges() {
        trackChanges(from: originalSettings, to: settings)
    }

    func updateVisibility(_ selection: PostVisibilityPicker.Selection) {
        track(.editorPostVisibilityChanged)

        switch selection.type {
        case .public, .protected:
            switch details {
            case .abstractPost(let post) where post.getOriginal().status == .scheduled:
                break // Keep it scheduled
            case .remotePost where settings.status == .scheduled:
                break // Keep it scheduled
            default:
                settings.status = .publish
            }
        case .private:
            settings.status = .publishPrivate
        }
        settings.password = selection.password.isEmpty ? nil : selection.password
    }

    func didSelectSuggestedTag(_ tag: String) {
        suggestedTags.removeAll(where: { $0 == tag })
        settings.tags.append(",\(tag)")

        track(.intelligenceSuggestedTagSelected)
    }

    func didSelectTags(_ tags: String) {
        settings.tags = tags
        isSuggestedTagsRefreshNeeded = true
    }

    func didSelectTerms(_ terms: String, forTaxonomySlug taxonomySlug: String) {
        settings.setTerms(terms, forTaxonomySlug: taxonomySlug)
    }

    // MARK: - Social Sharing

    private func refreshSocialSharingState() {
        guard let post = abstractPost as? Post, isPostEligibleForSocialSharing(post) else {
            socialSharingState = nil
            return
        }
        if (blog.connections ?? []).isEmpty {
            if isSocialConnectionSetupDismissed {
                socialSharingState = nil
            } else {
                socialSharingState = .setup(makeSocialSharingSetupViewModel())
            }
        } else {
            socialSharingState = .connected
        }
    }

    private func isPostEligibleForSocialSharing(_ post: Post) -> Bool {
        BuildSettings.current.brand == .jetpack &&
        RemoteFeatureFlag.jetpackSocialImprovements.enabled() &&
        post.status != .publishPrivate &&
        !getPublicizeServices().isEmpty &&
        blog.supports(.publicize)
    }

    private func getPublicizeServices() -> [PublicizeService] {
        let context = ContextManager.shared.mainContext
        return (try? PublicizeService.allPublicizeServices(in: context)) ?? []
    }

    /// Convenience variable representing whether the No Connection view has been dismissed.
    /// Note: the value is stored per site.
    private var isSocialConnectionSetupDismissed: Bool {
        get {
            guard let blogID = blog.dotComID?.intValue,
                  let dictionary = preferences.dictionary(forKey: Constants.noConnectionKey) as? [String: Bool],
                  let value = dictionary["\(blogID)"] else {
                return false
            }
            return value
        }
        set {
            guard let blogID = blog.dotComID?.intValue else {
                return wpAssertionFailure("blogID missing")
            }
            var dictionary = (preferences.dictionary(forKey: Constants.noConnectionKey) as? [String: Bool]) ?? .init()
            dictionary["\(blogID)"] = newValue
            preferences.set(dictionary, forKey: Constants.noConnectionKey)
        }
    }

    private func makeSocialSharingSetupViewModel() -> JetpackSocialNoConnectionViewModel {
        JetpackSocialNoConnectionViewModel(
            services: getPublicizeServices(),
            padding: .zero,
            onConnectTap: { [weak self] in self?.showSocialSharingSetupScreen() },
            onNotNowTap: { [weak self] in self?.didDismissSocialSharingSetupPrompt() }
        )
    }

    private func showSocialSharingSetupScreen() {
        guard let sharingVC = SharingViewController(blog: blog, delegate: self) else {
            return wpAssertionFailure("failed to instantiate SharingVC")
        }
        track(.jetpackSocialNoConnectionCTATapped)
        let navigationVC = UINavigationController(rootViewController: sharingVC)
        viewController?.present(navigationVC, animated: true)
    }

    private func didDismissSocialSharingSetupPrompt() {
        track(.jetpackSocialNoConnectionCardDismissed)
        isSocialConnectionSetupDismissed = true
        withAnimation {
            socialSharingState = nil
        }
    }

    func showSocialSharingOptions() {
        guard let blogID = blog.dotComID?.intValue,
              let settigns = settings.sharing else {
            return wpAssertionFailure("invalid context")
        }
        let optionsVC = PrepublishingSocialAccountsViewController(
            blogID: blogID,
            model: settigns,
            delegate: self,
            coreDataStack: ContextManager.shared
        )
        viewController?.navigationController?.pushViewController(optionsVC, animated: true)
    }

    // MARK: - Navigation

    func showCategoriesPicker() {
        let categoriesVC = PostSettingsCategoriesPickerViewController(
            blog: blog,
            selectedCategoryIDs: settings.categoryIDs
        ) { [weak self] newSelectedIDs in
            self?.settings.categoryIDs = newSelectedIDs
        }
        viewController?.navigationController?.pushViewController(categoriesVC, animated: true)
    }

    // MARK: - Analytics

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
}

extension PostSettingsViewModel: @MainActor SharingViewControllerDelegate {
    func didChangePublicizeServices() {
        refreshSocialSharingState()
    }
}

extension PostSettingsViewModel: @MainActor PrepublishingSocialAccountsDelegate {
    func didUpdateSharingLimit(with newValue: PublicizeInfo.SharingLimit?) {
        settings.sharing?.sharingLimit = newValue
    }

    func didFinish(with connectionChanges: [Int: Bool], message: String?) {
        guard var settings = settings.sharing else {
            return wpAssertionFailure("social sharing settings missing")
        }
        settings.services = settings.services.map {
            var service = $0
            service.connections = service.connections.map {
                var connection = $0
                if let isEnabled = connectionChanges[connection.keyringID] {
                    connection.enabled = isEnabled
                }
                return connection
            }
            return service
        }
        settings.message = message ?? ""
        self.settings.sharing = settings
    }
}

// MARK: - PostFormat Helpers

extension PostFormat {
    static func from(slug: String) -> PostFormat {
        switch slug {
        case "standard": return .standard
        case "aside": return .aside
        case "chat": return .chat
        case "gallery": return .gallery
        case "link": return .link
        case "image": return .image
        case "quote": return .quote
        case "status": return .status
        case "video": return .video
        case "audio": return .audio
        default: return .custom(slug)
        }
    }
}

private enum PostDetails {
    case abstractPost(AbstractPost)
    case remotePost(AnyPostWithEditContext, PostTypeDetailsWithEditContext)
}

// MARK: - Localized Strings

private enum Strings {
    static let postSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.post",
        value: "Post Settings",
        comment: "The title of the Post Settings screen."
    )

    static let pageSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.page",
        value: "Page Settings",
        comment: "The title of the Page Settings screen."
    )

    static let customPostSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.customPostType",
        value: "%1$@ Settings",
        comment: "The title of the Post Settings screen for custom post types. %1$@ is the post type name."
    )

    static let saveFailedMessage = NSLocalizedString(
        "postSettings.saveFailed.message",
        value: "Failed to save changes",
        comment: "Error message shown when saving post settings via REST API fails"
    )

    static let postDeletedTitle = NSLocalizedString(
        "postSettings.postDeleted.title",
        value: "Post Deleted",
        comment: "Title of alert when trying to save a deleted post"
    )

    static let pageDeletedTitle = NSLocalizedString(
        "postSettings.pageDeleted.title",
        value: "Page Deleted",
        comment: "Title of alert when trying to save a deleted page"
    )

    static let postDeletedMessage = NSLocalizedString(
        "postSettings.postDeleted.message",
        value: "This post has been deleted and can no longer be saved.",
        comment: "Message when trying to save a deleted post"
    )

    static let pageDeletedMessage = NSLocalizedString(
        "postSettings.pageDeleted.message",
        value: "This page has been deleted and can no longer be saved.",
        comment: "Message when trying to save a deleted page"
    )
}

private enum Constants {
    static let noConnectionKey = "prepublishing-social-no-connection-view-hidden"
}

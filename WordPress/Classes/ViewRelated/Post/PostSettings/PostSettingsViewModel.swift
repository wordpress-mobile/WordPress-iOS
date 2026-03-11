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
    let provider: PostSettingsDataProvider

    @Published var settings: PostSettings {
        didSet {
            refresh(from: oldValue, to: settings)
        }
    }

    @Published private(set) var isSaving = false
    @Published private(set) var hasChanges = false
    @Published private(set) var displayedCategories: [String] = []
    @Published private(set) var displayedTags: [String] = []
    @Published private(set) var isResolvingTags = false
    @Published private(set) var isResolvingCustomTerms = false
    @Published private(set) var suggestedTags: [String] = []
    @Published private(set) var customTaxonomies: [SiteTaxonomy] = []
    @Published private(set) var parentPageText: String?
    @Published private(set) var socialSharingState: SocialSharingSectionState?

    @Published var isShowingDeletedAlert = false

    /// The content of the post, used for AI excerpt generation.
    var postContent: String {
        provider.postContent
    }

    var navigationTitle: String {
        provider.navigationTitle
    }

    var deletedAlertTitle: String {
        isPost ? Strings.postDeletedTitle : Strings.pageDeletedTitle
    }

    var deletedAlertMessage: String {
        isPost ? Strings.postDeletedMessage : Strings.pageDeletedMessage
    }

    var isScheduled: Bool {
        provider.isScheduled
    }

    var authorDisplayName: String {
        settings.author?.displayName ?? provider.authorFallbackDisplayName
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
        provider.suggestedSlug
    }

    var permalinkTemplate: String? {
        provider.permalinkTemplate
    }

    var postFormatText: String {
        guard capabilities.supportsPostFormats else { return "" }
        return blog.postFormatText(fromSlug: settings.postFormat) ?? NSLocalizedString("Standard", comment: "Default post format")
    }

    var timeZone: TimeZone {
        blog.timeZone ?? TimeZone.current
    }

    var isDraftOrPending: Bool {
        provider.isDraftOrPending
    }

    var isPost: Bool {
        provider.isPost
    }

    var shouldShowStickyOption: Bool {
        // Sticky is exclusively a WordPress "post" type feature
        guard isPost else { return false }
        // Show sticky option if blog supports WPComRESTAPI OR user is admin
        return blog.supports(.wpComRESTAPI) || blog.isAdmin
    }

    var lastEditedText: String? {
        provider.lastEditedText
    }

    var postID: Int? {
        provider.postID
    }

    /// The underlying Page for the parent page picker.
    var page: Page? {
        // FIXME: This will be improved once we add parent page selection support to custom posts.
        (provider as? AbstractPostSettingsDataProvider)?.post as? Page
    }

    /// Whether the post has a remote representation (used for permalink preview).
    var hasRemote: Bool {
        provider.hasRemote
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

    // MARK: - Initializer

    init(
        provider: PostSettingsDataProvider,
        isStandalone: Bool = false,
        context: Context = .settings,
        preferences: UserPersistentRepository = UserDefaults.standard
    ) {
        self.provider = provider
        self.blog = provider.blog
        self.capabilities = provider.capabilities
        self.isStandalone = isStandalone
        self.context = context
        self.preferences = preferences
        self.client = try? WordPressClientFactory.shared.instance(for: .init(blog: provider.blog))

        let initialSettings = provider.makeSettings()
        self.settings = initialSettings
        self.originalSettings = initialSettings
        self.featuredImageViewModel = provider.makeFeaturedImageViewModel()

        super.init()

        featuredImageViewModel?.$selection.dropFirst().sink { [weak self] media in
            self?.settings.featuredImageID = media?.mediaID?.intValue
        }.store(in: &cancellables)

        refreshDisplayedCategories()
        refreshDisplayedTags()
        refreshCustomTaxonomies()
        refreshParentPageText()
        refreshSocialSharingState()
        resolveTerms()

        WPAnalytics.track(.postSettingsShown)
    }

    func onAppear() {
        refreshSuggestedTags()
    }

    func shouldShow(_ row: Row) -> Bool {
        guard provider.supportsJetpackMetadata else { return false }
        switch row {
        case .jetpackAccessLevel:
            return blog.supports(.wpComRESTAPI)
        case .jetpackNewsletterEmailOptions:
            return blog.supports(.wpComRESTAPI) && context == .publishing
        }
    }

    // MARK: - Suggested Tags

    private func refreshSuggestedTags() {
        guard isSuggestedTagsRefreshNeeded else { return }
        isSuggestedTagsRefreshNeeded = false

        let task = Task { @MainActor [weak self] in
            do {
                guard let self else { return }
                let tags = try await provider.suggestedTags()
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
        customTaxonomies = provider.customTaxonomies()
    }

    // MARK: - Term Resolution

    private func resolveTerms() {
        Task { [weak self] in
            guard let self else { return }

            isResolvingTags = true
            isResolvingCustomTerms = true

            var currentSettings = self.settings
            await provider.resolveTerms(in: &currentSettings)

            self.settings = currentSettings
            isResolvingTags = false
            isResolvingCustomTerms = false
            refreshDisplayedTags()
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
        displayedCategories = provider.resolveDisplayedCategories(for: settings)
    }

    private func refreshDisplayedTags() {
        displayedTags = settings.tags.map(\.name)
    }

    private func refreshParentPageText() {
        parentPageText = provider.parentPageText(for: settings.parentPageID)
    }

    // MARK: - Actions

    func buttonCancelTapped() {
        onDismiss?()
    }

    func buttonSaveTapped() {
        switch details {
        case .abstractPost(let post):
            buttonSaveTappedForAbstractPost(post)
        case .customPost:
            buttonSaveTappedForCustomPost()
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
            do {
                let settings = getSettingsToSave(for: self.settings)
                let coordinator = PostCoordinator.shared
                if coordinator.isSyncAllowed(for: post) && post.status == settings.status {
                    let revision = post.createRevision()
                    settings.apply(to: revision)
                    coordinator.setNeedsSync(for: revision)
                } else {
                    let changes = settings.makeUpdateParameters(from: post)
                    try await coordinator.save(post, changes: changes)
                }
                didSaveChanges()
                onDismiss?()
            } catch {
                isSaving = false
            }
        }
    }

    private func buttonSaveTappedForCustomPost() {
        guard let editorService else {
            wpAssertionFailure("missing editor service")
            return
        }

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
                Notice(error: error, title: Strings.saveFailedMessage).post()
            }
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
        case .customPost:
            publishCustomPost()
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

    private func publishCustomPost() {
        guard let editorService else {
            wpAssertionFailure("missing editor service")
            return
        }

        isSaving = true
        Task {
            do {
                try await editorService.save(settings: settings, publish: true)
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
            if isScheduled {
                break // Keep it scheduled
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
        isSuggestedTagsRefreshNeeded = true
    }

    func didSelectTerms(_ terms: [TagsViewModel.SelectedTerm], forTaxonomySlug taxonomySlug: String) {
        settings.otherTerms[taxonomySlug] = terms.map { PostSettings.Term(id: $0.id, name: $0.name) }
    }

    // MARK: - Social Sharing

    private func refreshSocialSharingState() {
        guard provider.isEligibleForSocialSharing else {
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

    private func getPublicizeServices() -> [PublicizeService] {
        let context = ContextManager.shared.mainContext
        return (try? PublicizeService.allSupportedServices(in: context)) ?? []
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

// MARK: - Localized Strings

private enum Strings {
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

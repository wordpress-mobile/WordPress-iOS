import Foundation
import BuildSettingsKit
import SwiftUI
import WordPressData
import WordPressKit
import WordPressCore
import WordPressShared
import WordPressAPIInternal
import Combine

@MainActor
final class PostSettingsViewModel: NSObject, ObservableObject {
    let post: AbstractPost
    let isStandalone: Bool
    let context: Context
    let featuredImageViewModel: PostSettingsFeaturedImageViewModel
    let client: WordPressClient?

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

    var navigationTitle: String {
        isPost ? Strings.postSettingsTitle : Strings.pageSettingsTitle
    }

    var deletedAlertTitle: String {
        isPost ? Strings.postDeletedTitle : Strings.pageDeletedTitle
    }

    var deletedAlertMessage: String {
        isPost ? Strings.postDeletedMessage : Strings.pageDeletedMessage
    }

    var authorDisplayName: String {
        settings.author?.displayName ?? post.author?.makePlainText() ?? ""
    }

    var authorAvatarURL: URL? {
        settings.author?.avatarURL
    }

    var emailToSubscribers: Bool {
        get { !settings.metadata.isJetpackNewsletterEmailDisabled }
        set { settings.metadata.isJetpackNewsletterEmailDisabled = !newValue }
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
        settings.slug.isEmpty ? (post.suggested_slug ?? "") : settings.slug
    }

    var postFormatText: String {
        guard let post = post as? Post else { return "" }
        return post.blog.postFormatText(fromSlug: settings.postFormat) ?? NSLocalizedString("Standard", comment: "Default post format")
    }

    var timeZone: TimeZone {
        post.blog.timeZone ?? TimeZone.current
    }

    var isDraftOrPending: Bool {
        post.getOriginal().isStatus(in: [.draft, .pending])
    }

    var isPost: Bool {
        post is Post
    }

    var shouldShowStickyOption: Bool {
        guard isPost else { return false }
        // Show sticky option if blog supports WPComRESTAPI OR user is admin
        return post.blog.supports(.wpComRESTAPI) || post.blog.isAdmin
    }

    var lastEditedText: String? {
        guard let date = post.dateModified ?? post.dateCreated else {
            return nil
        }
        return date.toMediumString()
    }

    var postID: Int? {
        guard let postID = post.postID?.intValue, postID > 0 else {
            return nil
        }
        return postID
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

    init(
        post: AbstractPost,
        isStandalone: Bool = false,
        context: Context = .settings,
        preferences: UserPersistentRepository = UserDefaults.standard
    ) {
        self.post = post
        self.isStandalone = isStandalone
        self.context = context
        self.preferences = preferences
        self.client = try? WordPressClient(site: .init(blog: post.blog))

        // Initialize settings from the post
        let initialSettings = PostSettings(from: post)
        self.settings = initialSettings
        self.originalSettings = initialSettings

        // Initialize featured image view model
        self.featuredImageViewModel = PostSettingsFeaturedImageViewModel(post: post)

        super.init()

        // Observe selection changes from featured image view model
        featuredImageViewModel.$selection.dropFirst().sink { [weak self] media in
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

    func onAppear() {
        refreshSuggestedTags()
    }

    func shouldShow(_ row: Row) -> Bool {
        switch row {
        case .jetpackAccessLevel:
            post.blog.supports(.wpComRESTAPI)
        case .jetpackNewsletterEmailOptions:
            post.blog.supports(.wpComRESTAPI) && context == .publishing
        }
    }

    private func refreshSuggestedTags() {
        guard isSuggestedTagsRefreshNeeded else {
            return
        }
        isSuggestedTagsRefreshNeeded = false

        let task = Task { @MainActor [weak self, post] in
            do {
                let tags = try await TagSuggestionsService().getSuggestedTags(for: post)
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
        let postType: String? = switch post {
            case is Post: "post"
            case is Page: "page"
            default: nil
            }
        guard let postType else { return }

        let customTaxonomies = try? post.blog.taxonomies
            .filter {
                $0.slug != "post_tag" && $0.slug != "category" && $0.supportedPostTypes.contains(postType)
            }
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
        displayedCategories = settings.getCategoryNames(for: post)
    }

    private func refreshDisplayedTags() {
        displayedTags = AbstractPost.makeTags(from: settings.tags)
    }

    private func refreshParentPageText() {
        if let page = post as? Page,
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
            await actuallySave()
        }
    }

    private func actuallySave() async {
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

    private func didSaveChanges() {
        trackChanges(from: originalSettings, to: settings)
    }

    func updateVisibility(_ selection: PostVisibilityPicker.Selection) {
        track(.editorPostVisibilityChanged)

        switch selection.type {
        case .public, .protected:
            if post.getOriginal().status == .scheduled {
                // Keep it scheduled
            } else {
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
        guard let post = post as? Post, isPostEligibleForSocialSharing(post) else {
            socialSharingState = nil
            return
        }
        if (post.blog.connections ?? []).isEmpty {
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
        post.blog.supportsPublicize()
    }

    private func getPublicizeServices() -> [PublicizeService] {
        let context = ContextManager.shared.mainContext
        return (try? PublicizeService.allPublicizeServices(in: context)) ?? []
    }

    /// Convenience variable representing whether the No Connection view has been dismissed.
    /// Note: the value is stored per site.
    private var isSocialConnectionSetupDismissed: Bool {
        get {
            guard let blogID = post.blog.dotComID?.intValue,
                  let dictionary = preferences.dictionary(forKey: Constants.noConnectionKey) as? [String: Bool],
                  let value = dictionary["\(blogID)"] else {
                return false
            }
            return value
        }
        set {
            guard let blogID = post.blog.dotComID?.intValue else {
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
        guard let sharingVC = SharingViewController(blog: post.blog, delegate: self) else {
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
        guard let blogID = post.blog.dotComID?.intValue,
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
            blog: post.blog,
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

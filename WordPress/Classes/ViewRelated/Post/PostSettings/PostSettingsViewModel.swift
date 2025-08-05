import Foundation
import WordPressData
import WordPressKit
import WordPressShared
import Combine

@MainActor
final class PostSettingsViewModel: ObservableObject {
    let post: AbstractPost
    let isStandalone: Bool
    let featuredImageViewModel: PostSettingsFeaturedImageViewModel

    @Published var settings: PostSettings {
        didSet {
            refresh(from: oldValue, to: settings)
        }
    }

    @Published private(set) var isSaving = false
    @Published private(set) var hasChanges = false
    @Published private(set) var displayedCategories: [String] = []
    @Published private(set) var displayedTags: [String] = []
    @Published private(set) var parentPageText: String?

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
        settings.author?.displayName ?? post.authorNameForDisplay()
    }

    var authorAvatarURL: URL? {
        settings.author?.avatarURL
    }

    var publishDateText: String? {
        guard let date = settings.publishDate else {
            return nil
        }
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
        post.original().isStatus(in: [.draft, .pending])
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

    private let originalSettings: PostSettings
    private var cancellables = Set<AnyCancellable>()

    var onDismiss: (() -> Void)?
    var onEditorPostSaved: (() -> Void)?

    /// Weak reference to the view controller for navigation.
    /// This is temporary until we can fully migrate to SwiftUI navigation.
    weak var viewController: UIViewController?

    init(post: AbstractPost, isStandalone: Bool = false) {
        self.post = post
        self.isStandalone = isStandalone

        // Initialize settings from the post
        let initialSettings = PostSettings(from: post)
        self.settings = initialSettings
        self.originalSettings = initialSettings

        // Initialize featured image view model
        self.featuredImageViewModel = PostSettingsFeaturedImageViewModel(post: post)

        // Observe selection changes from featured image view model
        featuredImageViewModel.$selection.dropFirst().sink { [weak self] media in
            self?.settings.featuredImageID = media?.mediaID?.intValue
        }.store(in: &cancellables)

        // Initialize all cached properties
        refreshDisplayedCategories()
        refreshDisplayedTags()
        refreshParentPageText()

        WPAnalytics.track(.postSettingsShown)
    }

    private func refresh(from old: PostSettings, to new: PostSettings) {
        hasChanges = new != originalSettings

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
            return
        }

        isSaving = true
        Task {
            await actuallySave()
        }
    }

    private func actuallySave() async {
        do {
            let coordinator = PostCoordinator.shared
            if coordinator.isSyncAllowed(for: post) {
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

    private func didSaveChanges() {
        trackChanges(from: originalSettings, to: settings)
    }

    func updateVisibility(_ selection: PostVisibilityPicker.Selection) {
        track(.editorPostVisibilityChanged)

        switch selection.type {
        case .public, .protected:
            if post.original().status == .scheduled {
                // Keep it scheduled
            } else {
                settings.status = .publish
            }
        case .private:
            settings.status = .publishPrivate
        }
        settings.password = selection.password.isEmpty ? nil : selection.password
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

    func showTagsPicker() {
        let tagsVC = TagsViewController(blog: post.blog, selectedTags: settings.tags) { [weak self] newTagsString in
            self?.settings.tags = newTagsString
        }
        viewController?.navigationController?.pushViewController(tagsVC, animated: true)
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
            WPAnalytics.track(.editorPostFeaturedImageChanged, properties: ["via": "settings", "action": action])
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
    }

    private func track(_ event: WPAnalyticsEvent) {
        WPAnalytics.track(event, properties: ["via": "settings"])
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

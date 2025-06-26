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
            refresh(with: settings)
            trackChanges(from: oldValue, to: settings)
        }
    }

    @Published private(set) var isSaving = false
    @Published private(set) var hasChanges = false
    @Published private(set) var categoriesText = ""
    @Published private(set) var tagsText = ""

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

    var isMultiAuthorBlog: Bool {
        post.blog.isMultiAuthor
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

    var timeZone: TimeZone {
        post.blog.timeZone ?? TimeZone.current
    }

    var isDraftOrPending: Bool {
        post.original().isStatus(in: [.draft, .pending])
    }

    var isPost: Bool {
        post is Post
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

        // Initialize cached text values
        refresh(with: settings)
    }

    private func refresh(with settings: PostSettings) {
        hasChanges = settings != originalSettings
        categoriesText = settings.makeCategoriesText(for: post)
            .stringByDecodingXMLCharacters()
        tagsText = settings.makeTagsText()
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
            // Apply settings and return to the editor
            settings.apply(to: post)
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
            onDismiss?()
        } catch {
            isSaving = false
            // `PostCoordinator` handles errors by showing an alert when needed
        }
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
        let tagsVC = PostTagPickerViewController(
            tags: settings.tags,
            blog: post.blog
        )
        tagsVC.onValueChanged = { [weak self] newTagsString in
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

import Foundation
import WordPressData
import WordPressKit
import WordPressShared

@MainActor
final class PostSettingsViewModel: ObservableObject {
    let post: AbstractPost
    let isStandalone: Bool

    @Published var settings: PostSettings {
        didSet {
            hasChanges = settings != originalSettings
            trackChanges(from: oldValue, to: settings)
        }
    }

    @Published private(set) var isSaving = false
    @Published private(set) var hasChanges = false
    @Published var isShowingDeletedAlert = false

    var navigationTitle: String {
        post is Page ? Strings.pageSettingsTitle : Strings.postSettingsTitle
    }

    var deletedAlertTitle: String {
        post is Page ? Strings.pageDeletedTitle : Strings.postDeletedTitle
    }

    var deletedAlertMessage: String {
        post is Page ? Strings.pageDeletedMessage : Strings.postDeletedMessage
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

    var publishDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if let date = settings.publishDate {
            return formatter.string(from: date)
        } else {
            return NSLocalizedString("postSettings.publishDate.immediately", value: "Immediately", comment: "Text shown when post will be published immediately")
        }
    }

    var visibilityText: String {
        switch settings.status {
        case .publishPrivate:
            return NSLocalizedString("postSettings.visibility.private", value: "Private", comment: "Post visibility: Private")
        default:
            if settings.password != nil && !settings.password!.isEmpty {
                return NSLocalizedString("postSettings.visibility.protected", value: "Password protected", comment: "Post visibility: Password protected")
            } else {
                return NSLocalizedString("postSettings.visibility.public", value: "Public", comment: "Post visibility: Public")
            }
        }
    }

    var timeZone: TimeZone {
        post.blog.timeZone ?? TimeZone.current
    }

    var isDraftOrPending: Bool {
        post.original().isStatus(in: [.draft, .pending])
    }

    private let originalSettings: PostSettings

    var onDismiss: (() -> Void)?
    var onEditorPostSaved: (() -> Void)?

    init(post: AbstractPost, isStandalone: Bool = false) {
        self.post = post
        self.isStandalone = isStandalone

        // Initialize settings from the post
        let initialSettings = PostSettings(from: post)
        self.settings = initialSettings
        self.originalSettings = initialSettings
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

    // MARK: - Analytics

    private func trackChanges(from old: PostSettings, to new: PostSettings) {
        func track(_ event: WPAnalyticsEvent) {
            WPAnalytics.track(event, properties: ["via": "settings"])
        }
        if old.author?.id != new.author?.id {
            track(.editorPostAuthorChanged)
        }
        if old.publishDate != new.publishDate {
            track(.editorPostScheduledChanged)
        }
        if old.status != new.status || old.password != new.password {
            track(.editorPostVisibilityChanged)
        }
        if old.tags != new.tags {
            track(.editorPostTagsChanged)
        }
        if old.postFormat != new.postFormat {
            track(.editorPostFormatChanged)
        }
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

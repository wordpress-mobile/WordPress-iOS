import Foundation
import WordPressData
import WordPressKit
import WordPressShared

@MainActor
final class PostSettingsViewModel: ObservableObject {
    private let post: AbstractPost
    let isStandalone: Bool

    @Published var settings: PostSettings {
        didSet {
            hasChanges = settings != originalSettings
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
                // Apply settings to the post and mark for sync
                settings.apply(to: post)
                coordinator.setNeedsSync(for: post)
            } else {
                // When sync is not allowed, use the changes parameter
                let changes = settings.makeUpdateParameters(from: originalSettings)
                try await coordinator.save(post, changes: changes)
            }
            onDismiss?()
        } catch {
            isSaving = false
            // `PostCoordinator` handles errors by showing an alert when needed
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

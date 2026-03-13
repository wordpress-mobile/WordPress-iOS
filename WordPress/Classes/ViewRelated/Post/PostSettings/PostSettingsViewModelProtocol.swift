import Foundation
import UIKit
import WordPressAPI
import WordPressCore
import WordPressData
import WordPressKit
import WordPressShared

// MARK: - Types

/// The context in which the post settings are displayed.
enum PostSettingsContext {
    case settings
    case publishing
}

/// Rows that can be conditionally shown in the post settings form.
enum PostSettingsRow {
    case jetpackAccessLevel
    case jetpackNewsletterEmailOptions
}

/// The state of the social sharing section.
enum PostSettingsSocialSharingSectionState {
    /// The initial prompt to set up connections.
    case setup(JetpackSocialNoConnectionViewModel)
    /// The site has existing connections.
    case connected
}

// MARK: - Protocol

/// Defines the contract for a post settings view model consumed by `PostSettingsView`
/// and related views. Two concrete implementations exist:
/// - `AbstractPostSettingsViewModel` for Core Data–backed posts/pages
/// - `CustomPostSettingsViewModel` for REST API–backed custom post types
@MainActor
protocol PostSettingsViewModelProtocol: ObservableObject {
    var blog: Blog { get }
    var capabilities: PostSettingsCapabilities { get }
    var isStandalone: Bool { get }
    var context: PostSettingsContext { get }
    var featuredImageViewModel: PostSettingsFeaturedImageViewModel? { get }
    var client: WordPressClient? { get }

    var settings: PostSettings { get set }
    var isSaving: Bool { get }
    var hasChanges: Bool { get }
    var displayedCategories: [String] { get }
    var displayedTags: [String] { get }
    var isResolvingTags: Bool { get }
    var isResolvingCustomTerms: Bool { get }
    var suggestedTags: [String] { get }
    var customTaxonomies: [SiteTaxonomy] { get }
    var parentPageText: String? { get }
    var socialSharingState: PostSettingsSocialSharingSectionState? { get }
    var isShowingDeletedAlert: Bool { get set }

    var postContent: String { get }
    var navigationTitle: String { get }
    var deletedAlertTitle: String { get }
    var deletedAlertMessage: String { get }
    var isScheduled: Bool { get }
    var authorDisplayName: String { get }
    var authorAvatarURL: URL? { get }
    var emailToSubscribers: Bool { get set }
    var accessLevel: JetpackPostAccessLevel { get set }
    var publishDateText: String? { get }
    var visibilityText: String { get }
    var slugText: String { get }
    var suggestedSlug: String? { get }
    var permalinkTemplate: String? { get }
    var postFormatText: String { get }
    var timeZone: TimeZone { get }
    var isDraftOrPending: Bool { get }
    var isPost: Bool { get }
    var shouldShowStickyOption: Bool { get }
    var lastEditedText: String? { get }
    var postID: Int? { get }
    var page: Page? { get }
    var hasRemote: Bool { get }
    var publishButtonTitle: String { get }

    var onDismiss: (() -> Void)? { get set }
    var onEditorPostSaved: (() -> Void)? { get set }
    var onPostPublished: (() -> Void)? { get set }
    var viewController: UIViewController? { get set }

    func onAppear()
    func shouldShow(_ row: PostSettingsRow) -> Bool
    func buttonCancelTapped()
    func buttonSaveTapped()
    func buttonPublishTapped()
    func getSettingsToSave(for settings: PostSettings) -> PostSettings
    func updateVisibility(_ selection: PostVisibilityPicker.Selection)
    func didSelectSuggestedTag(_ tag: String)
    func didSelectTags(_ tags: [TagsViewModel.SelectedTerm])
    func didSelectTerms(_ terms: [TagsViewModel.SelectedTerm], forTaxonomySlug: String)
    func showSocialSharingOptions()
    func showCategoriesPicker()
}

// MARK: - Date Formatting

enum PostSettingsDateFormatter {
    static func formattedDate(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
}

// MARK: - Localized Strings

enum PostSettingsStrings {
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

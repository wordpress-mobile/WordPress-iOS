
import UIKit

enum EditMode {
    case richText
    case html

    mutating func toggle() {
        switch self {
        case .richText:
            self = .html
        case .html:
            self = .richText
        }
    }
}

typealias EditorViewController = UIViewController & PostEditor
typealias ReplaceEditorCallback = (EditorViewController, EditorViewController) -> ()

/// Common interface to all editors
///
protocol PostEditor: PublishingEditor, UIViewControllerTransitioningDelegate {

    /// The post being edited.
    ///
    var post: AbstractPost { get set }

    /// Initializer
    ///
    /// - Parameters:
    ///     - post: the post to edit. Must be already assigned to a `ManagedObjectContext` since
    ///     that's necessary for the edits to be saved.
    ///     - loadAutosaveRevision: if true, apply autosave content when the editor creates a revision.
    ///     - replaceEditor: a closure that handles switching from one editor to another
    ///     - editorSession: post editor analytics session
    init(
        post: AbstractPost,
        loadAutosaveRevision: Bool,
        replaceEditor: @escaping ReplaceEditorCallback,
        editorSession: PostEditorAnalyticsSession?)

    /// Media items to be inserted on the post after creation
    ///
    /// - Parameter media: the media items to add
    ///
    func prepopulateMediaItems(_ media: [Media])

    /// Cancels all ongoing uploads
    ///
    func cancelUploadOfAllMedia(for post: AbstractPost)

    /// Whether the editor has failed media or not
    ///
    var hasFailedMedia: Bool { get }

    var isUploadingMedia: Bool { get }

    /// Verification prompt helper
    var verificationPromptHelper: VerificationPromptHelper? { get }

    /// Post editor state context
    var postEditorStateContext: PostEditorStateContext { get }

    /// Update editor UI with given html
    func setHTML(_ html: String)

    /// Return the current html in the editor
    func getHTML() -> String

    /// Title of the post
    var postTitle: String { get set }

    /// Describes the editor type to be used in analytics reporting
    var analyticsEditorSource: String { get }

    /// Error domain used when reporting error to Crash Logger
    var errorDomain: String { get }

    /// Returns true if the site mode is on
    var isSingleSiteMode: Bool { get }

    /// MediaLibraryPickerDataSource
    var mediaLibraryDataSource: MediaLibraryPickerDataSource { get set }

    /// Returns the media attachment removed version of html
    func contentByStrippingMediaAttachments() -> String

    /// Navigation bar manager for this post editor
    var navigationBarManager: PostEditorNavigationBarManager { get }

    /// Editor Session information for analytics reporting
    var editorSession: PostEditorAnalyticsSession { get set }

    /// Closure to call when the editor needs to be replaced with a different editor
    /// First argument is the existing editor, second argument is the replacement editor
    var replaceEditor: ReplaceEditorCallback { get }

    var autosaver: Autosaver { get set }

    /// true if the post is the result of a reblog
    var postIsReblogged: Bool { get set }

    /// From where the editor was shown (for analytics reporting)
    var entryPoint: PostEditorEntryPoint { get set }
}

extension PostEditor {

    var editorHasContent: Bool {
        return post.hasContent()
    }

    var editorHasChanges: Bool {
        return post.hasUnsavedChanges()
    }

    func editorContentWasUpdated() {
        postEditorStateContext.updated(hasContent: editorHasContent)
        postEditorStateContext.updated(hasChanges: editorHasChanges)
    }

    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var currentBlogCount: Int {
        return postIsReblogged ? BlogQuery().hostedByWPCom(true).count(in: mainContext) : Blog.count(in: mainContext)
    }

    var isSingleSiteMode: Bool {
        return currentBlogCount <= 1 || post.hasRemote()
    }

    var alertBarButtonItem: UIBarButtonItem? {
        return navigationBarManager.closeBarButtonItem
    }

    var prepublishingSourceView: UIView? {
        return navigationBarManager.publishButton
    }

    var prepublishingIdentifiers: [PrepublishingIdentifier] {
        if RemoteFeatureFlag.jetpackSocialImprovements.enabled() {
            return [.visibility, .schedule, .tags, .categories, .autoSharing]
        }

        return [.visibility, .schedule, .tags, .categories]
    }
}

enum PostEditorEntryPoint: String {
    case unknown
    case postsList
    case pagesList
    case dashboard
    case bloggingPromptsFeatureIntroduction = "blogging_prompts_introduction"
    case bloggingPromptsActionSheetHeader = "add_new_sheet_answer_prompt"
    case bloggingPromptsNotification = "blogging_reminders_notification_answer_prompt"
    case bloggingPromptsDashboardCard = "my_site_card_answer_prompt"
    case bloggingPromptsListView = "blogging_prompts_list_view"
}


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

/// Common interface to all editors
///
protocol PostEditor: class, UIViewControllerTransitioningDelegate {

    /// The post being edited.
    ///
    var post: AbstractPost { get set }

    /// Closure to be executed when the editor gets closed.
    ///
    var onClose: ((_ changesSaved: Bool, _ shouldShowPostPost: Bool) -> Void)? { get set }

    /// Whether the editor should open directly to the media picker.
    ///
    var isOpenedDirectlyForPhotoPost: Bool { get set }

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

    func removeFailedMedia()

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

    /// Debouncer used to save the post locally with a delay
    var debouncer: Debouncer { get }

    /// Navigation bar manager for this post editor
    var navigationBarManager: PostEditorNavigationBarManager { get }

    /// Editor Session information for analytics reporting
    var editorSession: PostEditorAnalyticsSession { get set }

    /// Closure to call when the editor needs to be replaced with a different editor
    /// First argument is the existing editor, second argument is the replacement editor
    var replaceEditor: (EditorViewController, EditorViewController) -> () { get }

    var autosaver: Autosaver { get set }
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
        let service = BlogService(managedObjectContext: mainContext)
        return service.blogCountForAllAccounts()
    }

    var isSingleSiteMode: Bool {
        return currentBlogCount <= 1 || post.hasRemote()
    }

    var uploadFailureNoticeTag: Notice.Tag {
        return "PostEditor.UploadFailed"
    }

    func uploadFailureNotice(action: PostEditorAction) -> Notice {
        return Notice(title: action.publishingErrorLabel, tag: uploadFailureNoticeTag)
    }
}

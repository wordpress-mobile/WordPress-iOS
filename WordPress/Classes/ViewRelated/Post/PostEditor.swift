
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

/// Common interface to all editors
///
protocol PostEditor: class, UIViewControllerTransitioningDelegate {
    /// Initialize editor with a post.
    ///
    init(post: AbstractPost)

    /// The post being edited.
    ///
    var post: AbstractPost { get set }

    /// Closure to be executed when the editor gets closed.
    ///
    var onClose: ((_ changesSaved: Bool, _ shouldShowPostPost: Bool) -> Void)? { get set }

    /// Whether the editor should open directly to the media picker.
    ///
    var isOpenedDirectlyForPhotoPost: Bool { get set }

    /// Boolean indicating whether the post should be removed whenever the changes are discarded, or not.
    ///
    var shouldRemovePostOnDismiss: Bool { get }

    /// Cancels all ongoing uploads
    ///
    ///TODO: We won't need this once media uploading is extracted to PostEditorUtil
    func cancelUploadOfAllMedia(for post: AbstractPost)

    /// Whether the editor has failed media or not
    ///
    //TODO: We won't need this once media uploading is extracted to PostEditorUtil
    var hasFailedMedia: Bool { get }

    //TODO: We won't need this once media uploading is extracted to PostEditorUtil
    var isUploadingMedia: Bool { get }

    //TODO: We won't need this once media uploading is extracted to PostEditorUtil
    //TODO: Otherwise the signature needs refactoring, it is too ambiguous for a protocol method
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

    /// Error domain used when reporting error to Crashlytics
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
}

extension PostEditor {

    var editorHasContent: Bool {
        return post.hasContent()
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

}

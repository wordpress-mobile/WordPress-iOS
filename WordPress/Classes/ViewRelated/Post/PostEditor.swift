
import UIKit

/// Common interface to all editors
///
protocol PostEditor: class {
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
}

protocol PublishablePostEditor: PostEditor {
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

    var navigationBarManager: PostEditorNavigationBarManager { get }
}

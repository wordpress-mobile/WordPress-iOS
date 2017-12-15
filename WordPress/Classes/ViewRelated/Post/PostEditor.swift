import CocoaLumberjack

/// Common interface to all editors
///
@objc protocol PostEditor: class {
    /// Initialize editor with a post.
    ///
    init(post: AbstractPost)

    /// The post being edited.
    ///
    var post: AbstractPost { get }

    /// Closure to be executed when the editor gets closed.
    ///
    var onClose: ((_ changesSaved: Bool) -> Void)? { get set }

    /// Whether the editor should open directly to the media picker.
    ///
    var isOpenedDirectlyForPhotoPost: Bool { get set }
}

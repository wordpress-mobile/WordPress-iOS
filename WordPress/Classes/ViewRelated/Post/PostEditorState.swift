import Foundation
import WordPressShared

/// The various states of the editor interface and all associated UI values
///
/// None of the associated values should be (nor can be) accessed directly by the UI, only through the `PostEditorStateContext` instance.
///
public enum PostEditorAction {
    case publish
    case update
    case submitForReview

    var publishActionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Publish", comment: "Label for the publish (verb) button. Tapping publishes a draft post.")
        case .submitForReview:
            return NSLocalizedString("Submit for Review", comment: "Submit for review button label (saving content, ex: Post, Page, Comment).")
        case .update:
            return NSLocalizedString("Update", comment: "Update button label (saving content, ex: Post, Page, Comment).")
        }
    }

    var analyticsEndOutcome: PostEditorAnalyticsSession.Outcome {
        switch self {
        case .update:
            return .save
            // TODO: make a new analytics event(s) for site creation homepage changes
        case .publish, .submitForReview:
            return .publish
        }
    }

    fileprivate var publishActionAnalyticsStat: WPAnalyticsStat {
        switch self {
        case .publish:
            return .editorPublishedPost
        case .update:
            return .editorUpdatedPost
        case .submitForReview:
            // TODO: When support is added for submit for review, add a new stat to support it
            return .editorPublishedPost
        }
    }
}

public protocol PostEditorStateContextDelegate: AnyObject {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction)
    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool)
}

/// Encapsulates all of the editor UI state based upon actions performed on the post being edited.
///
public class PostEditorStateContext {
    var action: PostEditorAction = .publish {
        didSet {
            if oldValue != action {
                delegate?.context(self, didChangeAction: action)
            }
        }
    }

    private var publishActionAllowed = false {
        didSet {
            if oldValue != publishActionAllowed {
                delegate?.context(self, didChangeActionAllowed: publishActionAllowed)
            }
        }
    }

    private weak var delegate: PostEditorStateContextDelegate?

    fileprivate var hasContent = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    fileprivate var hasChanges = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    fileprivate var isBeingPublished = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    fileprivate(set) var isUploadingMedia = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    convenience init(post: AbstractPost,
                     delegate: PostEditorStateContextDelegate,
                     action: PostEditorAction? = nil) {
        var originalPostStatus: BasePost.Status? = nil

        let originalPost = post.original()
        if let postStatus = originalPost.status, originalPost.hasRemote() {
            originalPostStatus = postStatus
        }

        // Self-hosted non-Jetpack blogs have no capabilities, so we'll default
        // to showing Publish Now instead of Submit for Review.
        //
        let userCanPublish = post.blog.capabilities != nil ? post.blog.isPublishingPostsAllowed() : true

        self.init(originalPostStatus: originalPostStatus,
                  userCanPublish: userCanPublish,
                  delegate: delegate)

        if let action {
            self.action = action
        }
    }

    /// The default initializer
    ///
    /// - Parameters:
    ///   - delegate: Delegate for listening to change in state for the editor
    ///
    required init(originalPostStatus: BasePost.Status? = nil, userCanPublish: Bool = true, delegate: PostEditorStateContextDelegate) {
        self.delegate = delegate
        self.action = PostEditorStateContext.initialAction(for: originalPostStatus, userCanPublish: userCanPublish)
    }

    private static func initialAction(for originalPostStatus: BasePost.Status?, userCanPublish: Bool) -> PostEditorAction {
        action(status: originalPostStatus ?? .draft, userCanPublish: userCanPublish)
    }

    static func action(status: BasePost.Status, userCanPublish: Bool) -> PostEditorAction {
        switch status {
        case .draft:
            return userCanPublish ? .publish : .submitForReview
        case .pending:
            return userCanPublish ? .publish : .update
        case .publishPrivate, .publish, .scheduled:
            return .update
        case .trash, .deleted:
            return .update // Should never happen (trashed posts are not be editable)
        }
    }

    /// Call whenever the post content is not empty - title or content body
    ///
    func updated(hasContent: Bool) {
        self.hasContent = hasContent
    }

    /// Call whenever the post content was updated - title or content body
    ///
    func updated(hasChanges: Bool) {
        self.hasChanges = hasChanges
    }

    /// Call when the post is being published or has finished
    ///
    func updated(isBeingPublished: Bool) {
        self.isBeingPublished = isBeingPublished
    }

    /// Call whenever a Media Upload OP is started / stopped
    ///
    func update(isUploadingMedia: Bool) {
        self.isUploadingMedia = isUploadingMedia
    }

    /// Should the publish button be enabled given the current state
    ///
    var isPublishButtonEnabled: Bool {
        return publishActionAllowed
    }

    /// Returns appropriate Publish button text for the current action
    /// e.g. Publish, Schedule, Update, Save
    ///
    var publishButtonText: String {
        return action.publishActionLabel
    }

    /// Returns the WPAnalyticsStat enum to be tracked when this post is published
    ///
    var publishActionAnalyticsStat: WPAnalyticsStat {
        return action.publishActionAnalyticsStat
    }

    /// Indicates whether the Publish Action should be allowed, or not
    ///
    private func updatePublishActionAllowed() {
        switch action {
        case .publish, .submitForReview:
            publishActionAllowed = hasContent
        case .update:
            publishActionAllowed = hasContent && hasChanges && !isBeingPublished
        }
    }
}

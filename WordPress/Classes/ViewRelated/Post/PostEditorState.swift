import Foundation
import WordPressShared

/// The various states of the editor interface and all associated UI values
///
/// None of the associated values should be (nor can be) accessed directly by the UI, only through the `PostEditorStateContext` instance.
///
public enum PostEditorAction {
    case save
    case saveAsDraft
    case schedule
    case publish
    case publishNow
    case update
    case submitForReview

    var dismissesEditor: Bool {
        switch self {
        case .publish, .publishNow, .schedule:
            return true
        default:
            return false
        }
    }

    fileprivate var publishActionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Publish", comment: "Label for the publish (verb) button. Tapping publishes a draft post.")
        case .publishNow:
            return NSLocalizedString("Publish Now", comment: "Title of button allowing the user to immediately publish the post they are editing.")
        case .save:
            return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
        case .saveAsDraft:
            return NSLocalizedString("Save as Draft", comment: "Title of button allowing users to change the status of the post they are currently editing to Draft.")
        case .schedule:
            return NSLocalizedString("Schedule", comment: "Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.")
        case .submitForReview:
            return NSLocalizedString("Submit for Review", comment: "Submit for review button label (saving content, ex: Post, Page, Comment).")
        case .update:
            return NSLocalizedString("Update", comment: "Update button label (saving content, ex: Post, Page, Comment).")
        }
    }

    var publishingActionLabel: String {
        switch self {
        case .publish, .publishNow:
            return NSLocalizedString("Publishing...", comment: "Text displayed in HUD while a post is being published.")
        case .save, .saveAsDraft:
            return NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
        case .schedule:
            return NSLocalizedString("Scheduling...", comment: "Text displayed in HUD while a post is being scheduled to be published.")
        case .submitForReview:
            return NSLocalizedString("Submitting for Review...", comment: "Text displayed in HUD while a post is being submitted for review.")
        case .update:
            return NSLocalizedString("Updating...", comment: "Text displayed in HUD while a draft or scheduled post is being updated.")
        }
    }

    var publishingErrorLabel: String {
        switch self {
        case .publish, .publishNow:
            return NSLocalizedString("Error occurred\nduring publishing", comment: "Text displayed in HUD while a post is being published.")
        case .schedule:
            return NSLocalizedString("Error occurred\nduring scheduling", comment: "Text displayed in HUD while a post is being scheduled to be published.")
        case .save, .saveAsDraft, .submitForReview, .update:
            return NSLocalizedString("Error occurred\nduring saving", comment: "Text displayed in HUD after attempting to save a draft post and an error occurred.")
        }
    }

    fileprivate var isPostPostShown: Bool {
        switch self {
        case .publish:
            return true
        default:
            return false
        }
    }

    fileprivate var secondaryPublishAction: PostEditorAction? {
        switch self {
        case .publish:
            return .saveAsDraft
        case .update:
            return .publishNow
        default:
            return nil
        }
    }

    fileprivate var publishActionAnalyticsStat: WPAnalyticsStat {
        switch self {
        case .save:
            return .editorSavedDraft
        case .saveAsDraft:
            return .editorQuickSavedDraft
        case .schedule:
            return .editorScheduledPost
        case .publish:
            return .editorPublishedPost
        case .publishNow:
            return .editorQuickPublishedPost
        case .update:
            return .editorUpdatedPost
        case .submitForReview:
            // TODO: When support is added for submit for review, add a new stat to support it
            return .editorPublishedPost
        }
    }
}

public protocol PostEditorStateContextDelegate: class {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction)
    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool)
}


/// Encapsulates all of the editor UI state based upon actions performed on the post being edited.
///
public class PostEditorStateContext {
    var action: PostEditorAction {
        didSet {
            delegate?.context(self, didChangeAction: action)
        }
    }

    private var publishActionAllowed = false {
        didSet {
            delegate?.context(self, didChangeActionAllowed: publishActionAllowed)
        }
    }

    fileprivate var originalPostStatus: BasePost.Status?
    fileprivate var currentPostStatus: BasePost.Status?
    fileprivate var currentPublishDate: Date?
    fileprivate var userCanPublish: Bool
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

    /// The default initializer
    ///
    /// - Parameters:
    ///   - originalPostStatus: If the post was already published (saved to the server) what is the status
    ///   - userCanPublish: Does the user have permission to publish posts or merely create drafts
    ///   - publishDate: The post publish date
    ///   - delegate: Delegate for listening to change in state for the editor
    ///
    init(originalPostStatus: BasePost.Status? = nil, userCanPublish: Bool = true, publishDate: Date? = nil, delegate: PostEditorStateContextDelegate) {
        self.originalPostStatus = originalPostStatus
        self.currentPostStatus = originalPostStatus
        self.userCanPublish = userCanPublish
        self.currentPublishDate = publishDate
        self.delegate = delegate

        guard let originalPostStatus = originalPostStatus else {
            action = .publish
            return
        }

        switch originalPostStatus {
        case .draft where userCanPublish == false:
            action = .submitForReview
        default:
            action = .update

        }
    }

    /// Call when the post status has changed due to a remote operation
    ///
    func updated(postStatus: BasePost.Status) {
        currentPostStatus = postStatus

        let updatedAction = { () -> PostEditorAction in
            switch postStatus {
            case .draft where originalPostStatus != nil && originalPostStatus != .draft:
                return .update
            case .draft, .pending:
                return .save
            case .publish where originalPostStatus == nil || originalPostStatus == .draft:
                if userCanPublish {
                    return .publish
                } else {
                    return .submitForReview
                }
            case .publish:
                return .update
            case .publishPrivate where originalPostStatus == nil || originalPostStatus == .draft:
                if userCanPublish {
                    return .publish
                } else {
                    return .submitForReview
                }
            case .publishPrivate:
                return .update
            case .scheduled where originalPostStatus == nil || originalPostStatus == .draft:
                if userCanPublish {
                    return .schedule
                } else {
                    return .submitForReview
                }
            case .scheduled:
                return .update
            case .deleted, .trash:
                // Deleted posts should really not be editable, but either way we'll try to handle it
                // gracefully by allowing a "Save" action, even it if failed.
                return .save
            }
        }()

        action = updatedAction
    }

    /// Call when the publish date has changed (picked a future date) or nil if publish immediately selected
    ///
    func updated(publishDate: Date?) {
        currentPublishDate = publishDate
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

    /// Indicates if the editor should be dismissed when the publish button is tapped
    ///
    var publishActionDismissesEditor: Bool {
        return action != .update
    }

    /// Should post-post be shown for the current editor when publishing has happened
    ///
    var isPostPostShown: Bool {
        return action.isPostPostShown
    }

    /// Returns whether the secondary publish button should be displayed, or not
    ///
    var isSecondaryPublishButtonShown: Bool {
        guard hasContent else {
            return false
        }

        // Don't show Publish Now for an already published or scheduled post with the update button as primary
        guard !((currentPostStatus == .publish || currentPostStatus == .scheduled) && action == .update) else {
            return false
        }

        // Don't show Publish Now for a draft with a future date
        guard !(currentPostStatus == .draft && isFutureDated(currentPublishDate)) else {
            return false
        }

        return action.secondaryPublishAction != nil
    }

    /// Returns the secondary publish action
    ///
    var secondaryPublishButtonAction: PostEditorAction? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return action.secondaryPublishAction
    }

    /// Returns the secondary publish button text
    ///
    var secondaryPublishButtonText: String? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return action.secondaryPublishAction?.publishActionLabel
    }

    /// Returns the WPAnalyticsStat enum to be tracked when this post is published with the secondary action
    var secondaryPublishActionAnalyticsStat: WPAnalyticsStat? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return action.secondaryPublishAction?.publishActionAnalyticsStat
    }


    /// Indicates whether the Publish Action should be allowed, or not
    ///
    private func updatePublishActionAllowed() {
        let actionIsPublish = action == .publish || action == .publishNow
        publishActionAllowed = hasContent && hasChanges && !isBeingPublished && (actionIsPublish || !isUploadingMedia)
    }
}

/// Helper methods for the entire state machine
///
fileprivate func isFutureDated(_ date: Date?) -> Bool {
    guard let date = date else {
        return false
    }

    let comparison = Calendar.current.compare(Date(), to: date, toGranularity: .minute)

    return comparison == .orderedAscending
}

fileprivate func isPastDated(_ date: Date?) -> Bool {
    guard let date = date else {
        return false
    }

    return date < Date()
}

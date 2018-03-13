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

/// Protocol used by all concrete states for the UI - never exposed outside of `PostEditorStateContext`
///
fileprivate protocol PostEditorActionState {
    var action: PostEditorAction { get }

    // Actions that change state
    func updated(postStatus: BasePost.Status, context: PostEditorStateContext) -> PostEditorActionState
    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState
}

public protocol PostEditorStateContextDelegate: class {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction)
    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool)
}


/// Encapsulates all of the editor UI state based upon actions performed on the post being edited.
///
public class PostEditorStateContext {
    private var editorState: PostEditorActionState {
        didSet {
            delegate?.context(self, didChangeAction: editorState.action)
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
            editorState = PostEditorStatePublish()
            return
        }

        switch originalPostStatus {
        case .draft where userCanPublish == false:
            editorState = PostEditorStateSubmitForReview()
        default:
            editorState = PostEditorStateUpdate()
        }
    }

    /// Call when the post status has changed due to a remote operation
    ///
    func updated(postStatus: BasePost.Status) {
        currentPostStatus = postStatus
        let updatedState = editorState.updated(postStatus: postStatus, context: self)
        guard type(of: editorState) != type(of: updatedState) else {
            return
        }

        editorState = updatedState
    }

    /// Call when the publish date has changed (picked a future date) or nil if publish immediately selected
    ///
    func updated(publishDate: Date?) {
        currentPublishDate = publishDate

        let updatedState = editorState.updated(publishDate: publishDate, context: self)
        guard type(of: editorState) != type(of: updatedState) else {
            return
        }

        editorState = updatedState
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

    /// Returns the current PostEditorAction state the UI is in
    ///
    var action: PostEditorAction {
        return editorState.action
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
        return editorState.action.publishActionLabel
    }

    /// Returns the WPAnalyticsStat enum to be tracked when this post is published
    ///
    var publishActionAnalyticsStat: WPAnalyticsStat {
        return editorState.action.publishActionAnalyticsStat
    }

    /// Indicates if the editor should be dismissed when the publish button is tapped
    ///
    var publishActionDismissesEditor: Bool {
        return editorState.action != .update
    }

    /// Should post-post be shown for the current editor when publishing has happened
    ///
    var isPostPostShown: Bool {
        return editorState.action.isPostPostShown
    }

    /// Returns whether the secondary publish button should be displayed, or not
    ///
    var isSecondaryPublishButtonShown: Bool {
        guard hasContent else {
            return false
        }

        // Don't show Publish Now for an already published or scheduled post with the update button as primary
        guard !((currentPostStatus == .publish || currentPostStatus == .scheduled) && editorState.action == .update) else {
            return false
        }

        // Don't show Publish Now for a draft with a future date
        guard !(currentPostStatus == .draft && isFutureDated(currentPublishDate)) else {
            return false
        }

        return editorState.action.secondaryPublishAction != nil
    }

    /// Returns the secondary publish action
    ///
    var secondaryPublishButtonAction: PostEditorAction? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return editorState.action.secondaryPublishAction
    }

    /// Returns the secondary publish button text
    ///
    var secondaryPublishButtonText: String? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return editorState.action.secondaryPublishAction?.publishActionLabel
    }

    /// Returns the WPAnalyticsStat enum to be tracked when this post is published with the secondary action
    var secondaryPublishActionAnalyticsStat: WPAnalyticsStat? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return editorState.action.secondaryPublishAction?.publishActionAnalyticsStat
    }


    /// Indicates whether the Publish Action should be allowed, or not
    ///
    private func updatePublishActionAllowed() {
        publishActionAllowed = hasContent && hasChanges && !isBeingPublished && !isUploadingMedia
    }
}

/// Concrete State for Publish
///
fileprivate class PostEditorStatePublish: PostEditorActionState {
    var action: PostEditorAction {
        return .publish
    }

    func updated(postStatus: BasePost.Status, context: PostEditorStateContext) -> PostEditorActionState {
        switch postStatus {
        case .draft where context.originalPostStatus == .publish:
            // If switching to a draft the post should show Update
            return PostEditorStateUpdate()
        case .draft:
            // Posts switching to Draft should show Save
            return PostEditorStateSave()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        if isFutureDated(publishDate) {
            // When future scheduling, button should show Schedule
            return PostEditorStateSchedule()
        }

        return self
    }
}

/// Concrete State for Save
///
fileprivate class PostEditorStateSave: PostEditorActionState {
    var action: PostEditorAction {
        return .save
    }

    func updated(postStatus: BasePost.Status, context: PostEditorStateContext) -> PostEditorActionState {
        switch postStatus {
        case .publish:
            // If a draft is published, it should show Update
            return PostEditorStateUpdate()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        if isFutureDated(publishDate) {
            // When future scheduling a draft, button should show Schedule
            return PostEditorStateSchedule()
        }

        return self
    }
}

/// Concrete State for Schedule
///
fileprivate class PostEditorStateSchedule: PostEditorActionState {
    var action: PostEditorAction {
        return .schedule
    }

    func updated(postStatus: BasePost.Status, context: PostEditorStateContext) -> PostEditorActionState {
        switch postStatus {
        case .scheduled:
            // When a post is scheduled, button should transition to Update
            return PostEditorStateUpdate()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        if isFutureDated(publishDate) == false {
            // If a post changed to a future date then back, button should be Publish again
            return PostEditorStatePublish()
        }

        return self
    }
}

/// Concrete State for Submit for Review
///
fileprivate class PostEditorStateSubmitForReview: PostEditorActionState {
    var action: PostEditorAction {
        return .submitForReview
    }

    func updated(postStatus: BasePost.Status, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }
}

/// Concrete State for Update
///
fileprivate class PostEditorStateUpdate: PostEditorActionState {
    var action: PostEditorAction {
        return .update
    }

    func updated(postStatus: BasePost.Status, context: PostEditorStateContext) -> PostEditorActionState {
        switch postStatus {
        case .publish:
            // If a draft is published immediately, change state to Publish
            return PostEditorStatePublish()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        if isFutureDated(publishDate) && context.originalPostStatus != .scheduled {
            return PostEditorStateSchedule()
        }

        if isPastDated(publishDate) && context.originalPostStatus == .scheduled {
            return PostEditorStatePublish()
        }

        return self
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

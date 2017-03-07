import Foundation

/// The various states of the editor interface and all associated UI values
///
/// None of the associated values should be (nor can be) accessed directly by the UI, only through the `PostEditorStateContext` instance.
///
public enum PostEditorAction {
    case save
    case schedule
    case publish
    case update
    case submitForReview

    fileprivate var publishActionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Publish", comment: "Publish button label.")
        case .save:
            return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
        case .schedule:
            return NSLocalizedString("Schedule", comment: "Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.")
        case .submitForReview:
            return NSLocalizedString("Submit for Review", comment: "Submit for review button label (saving content, ex: Post, Page, Comment).")
        case .update:
            return NSLocalizedString("Update", comment: "Update button label (saving content, ex: Post, Page, Comment).")
        }
    }

    fileprivate var publishingActionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Publishing...", comment: "Text displayed in HUD while a post is being published.")
        case .save:
            return NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
        case .schedule:
            return NSLocalizedString("Scheduling...", comment: "Text displayed in HUD while a post is being scheduled to be published.")
        case .submitForReview:
            return NSLocalizedString("Submitting for Review...", comment: "Text displayed in HUD while a post is being submitted for review.")
        case .update:
            return NSLocalizedString("Updating...", comment: "Text displayed in HUD while a draft or scheduled post is being updated.")
        }
    }

    fileprivate var publishingErrorLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Error occurred\nduring publishing", comment: "Text displayed in HUD while a post is being published.")
        case .schedule:
            return NSLocalizedString("Error occurred\nduring scheduling", comment: "Text displayed in HUD while a post is being scheduled to be published.")
        case .save, .submitForReview, .update:
            return NSLocalizedString("Error occurred\nduring saving", comment: "Text displayed in HUD after attempting to save a draft post and an error occurred.")
        }
    }

    fileprivate var secondaryPublishActionLabel: String? {
        switch self {
        case .publish:
            return NSLocalizedString("Publish Now", comment: "Title of button allowing the user to immediately publish the post they are editing.")
        case .save:
            return NSLocalizedString("Save as Draft", comment: "Title of button allowing users to change the status of the post they are currently editing to Draft.")
        default:
            return nil
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
            return .save
        case .update:
            return .publish
        default:
            return nil
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

    fileprivate var isUploadingMedia = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    /// The default initializer
    ///
    /// - Parameters:
    ///   - originalPostStatus: If the post was already published (saved to the server) what is the status
    ///   - userCanPublish: Does the user have permission to publish posts or merely create drafts
    ///   - delegate: Delegate for listening to change in state for the editor
    ///
    init(originalPostStatus: BasePost.Status? = nil, userCanPublish: Bool = true, delegate: PostEditorStateContextDelegate) {
        self.originalPostStatus = originalPostStatus
        self.userCanPublish = userCanPublish
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
        let updatedState = editorState.updated(postStatus: postStatus, context: self)
        guard type(of: editorState) != type(of: updatedState) else {
            return
        }

        editorState = updatedState
    }

    /// Call when the publish date has changed (picked a future date) or nil if publish immediately selected
    ///
    func updated(publishDate: Date?) {
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

    /// Returns appropriate publishing UI text text for the current action
    /// e.g. Publishing...
    ///
    var publishVerbText: String {
        return editorState.action.publishingActionLabel
    }

    /// Returns the Error Text for the current active action
    ///
    var publishErrorText: String {
        return editorState.action.publishingErrorLabel
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

        return editorState.action.secondaryPublishAction?.secondaryPublishActionLabel
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
        return self
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

/// Helper methods for all concrete PostEditorActionState classes
///
fileprivate extension PostEditorActionState {
    func isFutureDated(_ date: Date?) -> Bool {
        guard let date = date else {
            return false
        }

        let comparison = Calendar.current.compare(Date(), to: date, toGranularity: .minute)

        return comparison == .orderedAscending
    }

    func isPastDated(_ date: Date?) -> Bool {
        guard let date = date else {
            return false
        }

        return date < Date()
    }
}

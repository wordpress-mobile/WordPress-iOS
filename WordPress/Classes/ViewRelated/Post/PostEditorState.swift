import Foundation

// Taken from AbstractPost.m
enum PostStatus: String {
    case draft = "draft"
    case pending = "pending"
    case publishPrivate = "private"
    case publish = "publish"
    case scheduled = "future"
    case trash = "trash"
    case deleted = "deleted" // Returned by wpcom REST API when a post is permanently deleted.
}

public enum PostEditorAction {
    case save
    case schedule
    case publish
    case update
    case submitForReview

    var publishActionLabel: String {
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

    var publishingActionLabel: String {
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

    var isPostPostShown: Bool {
        switch self {
        case .publish:
            return true
        default:
            return false
        }
    }
}

fileprivate protocol PostEditorActionState {
    func action() -> PostEditorAction

    // Actions that change state
    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorActionState
    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState

    // Things that change with each state
    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool
}

public protocol PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction)
    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool)
}

public class PostEditorStateContext {
    private var editorState: PostEditorActionState {
        didSet {
            delegate?.context(self, didChangeAction: editorState.action())
        }
    }

    private var publishActionAllowed = false {
        didSet {
            delegate?.context(self, didChangeActionAllowed: publishActionAllowed)
        }
    }

    fileprivate var originalPostStatus: PostStatus
    fileprivate var userCanPublish: Bool
    private var delegate: PostEditorStateContextDelegate?

    fileprivate var hasContent = false {
        didSet {
            if hasContent != oldValue {
                publishActionAllowed = hasContent && !isBeingPublished
            }
        }
    }
    fileprivate var isDirty = false
    fileprivate var isBeingPublished = false {
        didSet {
            if isBeingPublished != oldValue {
                publishActionAllowed = hasContent && !isBeingPublished
            }
        }
    }

    init(originalPostStatus: PostStatus, userCanPublish: Bool = true, delegate: PostEditorStateContextDelegate) {
        self.originalPostStatus = originalPostStatus
        self.userCanPublish = userCanPublish
        self.delegate = delegate

        switch originalPostStatus {
        case .draft where userCanPublish == false:
            editorState = PostEditorStateSubmitForReview()
        case .draft:
            editorState = PostEditorStatePublish()
        default:
            editorState = PostEditorStateUpdate()
        }
    }

    func updated(postStatus: PostStatus) {
        let updatedState = editorState.updated(postStatus: postStatus, context: self)
        guard type(of: editorState) != type(of: updatedState) else {
            return
        }

        editorState = updatedState
    }

    func updated(publishDate: Date?) {
        let updatedState = editorState.updated(publishDate: publishDate, context: self)
        guard type(of: editorState) != type(of: updatedState) else {
            return
        }

        editorState = updatedState
    }

    func updated(hasContent: Bool) {
        self.hasContent = hasContent
    }

    func updated(isDirty: Bool) {
        self.isDirty = isDirty
    }

    func updated(isBeingPublished: Bool) {
        self.isBeingPublished = isBeingPublished
    }

    var action: PostEditorAction {
        return editorState.action()
    }

    var publishButtonText: String {
        return editorState.action().publishActionLabel
    }

    var publishVerbText: String {
        return editorState.action().publishingActionLabel
    }

    var isPostPostShown: Bool {
        return editorState.action().isPostPostShown
    }

    var isSecondaryPublishButtonShown: Bool {
        return editorState.isSecondaryPublishButtonShown(context: self)
    }

    var isPublishButtonEnabled: Bool {
        return publishActionAllowed
    }

}

fileprivate class PostEditorStatePublish: PostEditorActionState {
    func action() -> PostEditorAction {
        return .publish
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorActionState {
        switch postStatus {
        case .draft where context.originalPostStatus == .publish:
            return PostEditorStateUpdate()
        case .draft:
            return PostEditorStateSave()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        guard let publishDate = publishDate else {
            return self
        }

        if isFutureDated(publishDate) {
            return PostEditorStateSchedule()
        }

        return self
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate class PostEditorStateSave: PostEditorActionState {
    func action() -> PostEditorAction {
        return .save
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorActionState {
        switch postStatus {
        case .publish:
            return PostEditorStateUpdate()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        guard let publishDate = publishDate else {
            return self
        }

        if isFutureDated(publishDate) {
            return PostEditorStateSchedule()
        }

        return self
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate class PostEditorStateSchedule: PostEditorActionState {
    func action() -> PostEditorAction {
        return .schedule
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate class PostEditorStateSubmitForReview: PostEditorActionState {
    func action() -> PostEditorAction {
        return .submitForReview
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate class PostEditorStateUpdate: PostEditorActionState {
    func action() -> PostEditorAction {
        return .update
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorActionState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorActionState {
        guard let publishDate = publishDate else {
            return self
        }

        if isFutureDated(publishDate) && context.originalPostStatus != .scheduled {
            return PostEditorStateSchedule()
        }

        if isPastDated(publishDate) && context.originalPostStatus == .scheduled {
            return PostEditorStatePublish()
        }

        return self
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate extension PostEditorActionState {
    func isFutureDated(_ date: Date) -> Bool {
        let oneMinute: TimeInterval = 60.0
        let dateOneMinuteFromNow = Date(timeInterval: oneMinute, since: Date())

        return dateOneMinuteFromNow < date
    }

    func isPastDated(_ date: Date) -> Bool {
        return date < Date()
    }
}

import Foundation

enum PostStatus: String {
    case draft = "draft"
    case pending = "pending"
    case publishPrivate = "private"
    case publish = "publish"
    case scheduled = "future"
    case trash = "trash"
    case deleted = "deleted" // Returned by wpcom REST API when a post is permanently deleted.
}

public enum PostStatusState {
    case new
    case drafted
    case published
    case scheduled
    case submittedForReview
    case updated
    case trashed
}

fileprivate protocol PostEditorState {
    func state() -> PostStatusState

    // Actions that change state
    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState
    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState

    // Things that change with each state
    func getPublishButtonText(context: PostEditorStateContext) -> String
    func getPublishVerbText(context: PostEditorStateContext) -> String
    func isPostPostShown(context: PostEditorStateContext) -> Bool
    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool
}

public protocol PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeState: PostStatusState)
}

public class PostEditorStateContext {
    private var editorState: PostEditorState = PostEditorStateNew() {
        didSet {
            delegate?.context(self, didChangeState: editorState.state())
        }
    }

    private var userCanPublish = true
    private var delegate: PostEditorStateContextDelegate?

    private var hasContent = false
    private var isDirty = false
    private var isBeingPublished = false

    init(userCanPublish: Bool = true, delegate: PostEditorStateContextDelegate) {
        self.userCanPublish = userCanPublish
        self.delegate = delegate
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

    var state: PostStatusState {
        return editorState.state()
    }

    var publishButtonText: String {
        return editorState.getPublishButtonText(context: self)
    }

    var publishVerbText: String {
        return editorState.getPublishVerbText(context: self)
    }

    var isPostPostShown: Bool {
        return editorState.isPostPostShown(context: self)
    }

    var isSecondaryPublishButtonShown: Bool {
        return editorState.isSecondaryPublishButtonShown(context: self)
    }

    var isPublishButtonEnabled: Bool {
        return hasContent
    }

}

fileprivate class PostEditorStateNew: PostEditorState {
    func state() -> PostStatusState {
        return .new
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState {
        switch postStatus {
        case .publish:
            return PostEditorStatePublished()
        default:
            return self
        }
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func getPublishButtonText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Publish", comment: "Publish button label.")
    }

    func getPublishVerbText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Publishing...", comment: "Text displayed in HUD while a post is being published.")
    }

    func isPostPostShown(context: PostEditorStateContext) -> Bool {
        return true
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate class PostEditorStateDrafted: PostEditorState {
    func state() -> PostStatusState {
        return .drafted
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func getPublishButtonText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Publish", comment: "Publish button label.")
    }

    func getPublishVerbText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Publishing...", comment: "Text displayed in HUD while a post is being published.")
    }

    func isPostPostShown(context: PostEditorStateContext) -> Bool {
        return true
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}


fileprivate class PostEditorStatePublished: PostEditorState {
    func state() -> PostStatusState {
        return .published
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func getPublishButtonText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
    }

    func getPublishVerbText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
    }

    func isPostPostShown(context: PostEditorStateContext) -> Bool {
        return true
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

fileprivate class PostEditorStateScheduled: PostEditorState {
    func state() -> PostStatusState {
        return .scheduled
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func getPublishButtonText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
    }

    func getPublishVerbText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
    }

    func isPostPostShown(context: PostEditorStateContext) -> Bool {
        return true
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}


fileprivate class PostEditorStateSubmittedForReview: PostEditorState {
    func state() -> PostStatusState {
        return .submittedForReview
    }

    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState {
        return self
    }

    func getPublishButtonText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
    }

    func getPublishVerbText(context: PostEditorStateContext) -> String {
        return NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
    }

    func isPostPostShown(context: PostEditorStateContext) -> Bool {
        return true
    }

    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool {
        return false
    }
}

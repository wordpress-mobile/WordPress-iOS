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

enum PostStatusState {
    case new
    case drafted
    case published
    case scheduled
    case submittedForReview
    case updated
    case trashed
}

protocol PostEditorState {
    // Actions that change state
    func updated(postStatus: PostStatus, context: PostEditorStateContext) -> PostEditorState
    func updated(publishDate: Date?, context: PostEditorStateContext) -> PostEditorState

    // Things that change with each state
    func getPublishButtonText(context: PostEditorStateContext) -> String
    func getPublishVerbText(context: PostEditorStateContext) -> String
    func isPostPostShown(context: PostEditorStateContext) -> Bool
    func isSecondaryPublishButtonShown(context: PostEditorStateContext) -> Bool
}

protocol PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeState: PostEditorState)

}

class PostEditorStateContext {
    private var state: PostEditorState = PostEditorStateNew()
    private var userCanPublish = true
    private var delegate: PostEditorStateContextDelegate?

    init(withPost post: AbstractPost, previousPost: AbstractPost, userCanPublish: Bool = true, delegate: PostEditorStateContextDelegate) {
        self.userCanPublish = userCanPublish
        self.delegate = delegate
    }

    func updated(postStatus: PostStatus) {

    }

    func updated(publishDate: Date?) {

    }

    func getPublishButtonText() -> String {
        return state.getPublishButtonText(context: self)
    }

    func getPublishVerbText() -> String {
        return state.getPublishVerbText(context: self)
    }

    func isPostPostShown() -> Bool {
        return state.isPostPostShown(context: self)
    }

    func isSecondaryPublishButtonShown() -> Bool {
        return state.isSecondaryPublishButtonShown(context: self)
    }

    func isPublishButtonEnabled() -> Bool {
        return true
    }

}

class PostEditorStateNew: PostEditorState {
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

class PostEditorStateDrafted: PostEditorState {
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

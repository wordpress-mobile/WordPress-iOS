final class CommentModerationViewModel: ObservableObject {
    @Published var state: CommentModerationState
    let imageURL: URL?
    let userName: String

    // Temporary init argument
    init(state: CommentModerationState, imageURL: URL?, userName: String) {
        self.state = state
        self.imageURL = imageURL
        self.userName = userName
    }

    func didChangeState(to state: CommentModerationState) {
        // TODO
    }

    func didTapReply() {
        // TODO
    }

    func didTapPrimaryCTA() {
        switch state {
        case .pending:
            state = .approved
        case .trash:
            () // Delete comment
        case .approved, .liked:
            break
        }
    }

    func didTapMore() {
        // TODO
    }

    func didTapLike() {
        state = state == .approved ? .liked : .approved
    }
}

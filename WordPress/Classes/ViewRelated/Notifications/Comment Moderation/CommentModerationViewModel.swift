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
            state = .approved(liked: false)
        case .trash, .spam:
            () // Delete comment
        case .approved:
            break
        }
    }

    func didTapMore() {
        // TODO
    }

    func didTapLike() {
        switch state {
        case .approved(let liked):
            state = .approved(liked: !liked)
        default:
            break
        }
    }
}

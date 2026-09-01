import WordPressComments

@MainActor
struct NoticePresenterAdapter: NoticePresenting {
    func present(title: String) {
        Notice(title: title).post()
    }
}

@testable import WordPressComments

@MainActor
final class FakeNoticePresenter: NoticePresenting {
    /// The titles presented, in order.
    private(set) var presented: [String] = []

    func present(title: String) {
        presented.append(title)
    }
}

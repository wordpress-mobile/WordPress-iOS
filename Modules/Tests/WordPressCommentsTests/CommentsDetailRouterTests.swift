import Foundation
import Testing
import UIKit
@testable import WordPressComments

@MainActor
struct CommentsDetailRouterTests {
    @Test func openPushesDetailOntoHostNavigationStack() {
        let host = UIViewController()
        let navigation = UINavigationController(rootViewController: host)
        let router = CommentsDetailRouter(
            service: FakeCommentsService(),
            capabilities: FakeCommentsCapabilities(),
            coordinator: CommentsModerationCoordinator(service: FakeCommentsService()),
            titleResolver: PostTitleResolver(fetcher: { _ in .init(titles: [:]) }),
            tracker: nil,
            noticePresenter: FakeNoticePresenter(),
            makeContentRenderer: { FakeContentRenderer() }
        )
        router.host = host

        router.open(id: 1, seed: nil)

        #expect(navigation.viewControllers.count == 2)
    }
}

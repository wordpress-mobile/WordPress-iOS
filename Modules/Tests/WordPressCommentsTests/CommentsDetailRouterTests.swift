import Foundation
import Testing
import UIKit
@testable import WordPressComments

@MainActor
struct CommentsDetailRouterTests {
    @Test func openPushesDetailOntoHostNavigationStack() {
        let host = UIViewController()
        let navigation = UINavigationController(rootViewController: host)
        let router = makeRouter(capabilities: FakeCommentsCapabilities())
        router.host = host

        router.open(id: 1, seed: nil)

        #expect(navigation.viewControllers.count == 2)
    }

    @Test func resolvesCapabilityOnceAndRetriesAfterFailure() async {
        let capabilities = FakeCommentsCapabilities()
        capabilities.error = FakeServiceError()
        let router = makeRouter(capabilities: capabilities)
        router.host = UINavigationController(rootViewController: UIViewController()).viewControllers[0]

        // Resolved while the list loads; the failure is not cached.
        await waitUntil { capabilities.invocations == 1 }
        capabilities.error = nil
        router.open(id: 1, seed: nil)
        await waitUntil { capabilities.invocations == 2 }

        // Once known, later opens reuse the answer.
        router.open(id: 2, seed: nil)
        for _ in 0..<10 { await Task.yield() }
        #expect(capabilities.invocations == 2)
    }

    private func makeRouter(capabilities: FakeCommentsCapabilities) -> CommentsDetailRouter {
        CommentsDetailRouter(
            service: FakeCommentsService(),
            capabilities: capabilities,
            coordinator: CommentsModerationCoordinator(service: FakeCommentsService()),
            titleResolver: PostTitleResolver(fetcher: { _ in .init(titles: [:]) }),
            tracker: nil,
            noticePresenter: FakeNoticePresenter(),
            makeContentRenderer: { FakeContentRenderer() }
        )
    }
}

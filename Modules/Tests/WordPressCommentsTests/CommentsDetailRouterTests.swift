import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentsDetailRouterTests {
    @Test func makesDetailViewModelWithRequestedIdentityAndSeed() {
        let router = makeRouter(capabilities: FakeCommentsCapabilities())
        let seed = makeItem(id: 42, authorName: "Seed author")

        let viewModel = router.makeViewModel(id: 42, seed: seed)

        #expect(viewModel.commentID == 42)
        #expect(viewModel.header?.authorName == "Seed author")
    }

    @Test func makesRendererWithLinkHandler() throws {
        let router = makeRouter(capabilities: FakeCommentsCapabilities())

        let renderer = try #require(router.makeRenderer() as? FakeContentRenderer)

        #expect(renderer.onLinkTapped != nil)
    }

    @Test func makeViewModelReusesCapabilityAndRetriesAfterFailure() async {
        let capabilities = FakeCommentsCapabilities()
        capabilities.error = FakeServiceError()
        let router = makeRouter(capabilities: capabilities)

        // Resolved while the list loads; the failure is not cached.
        await waitUntil { capabilities.invocations == 1 }
        capabilities.error = nil
        _ = router.makeViewModel(id: 1, seed: nil)
        await waitUntil { capabilities.invocations == 2 }

        // Once known, later detail screens reuse the answer.
        _ = router.makeViewModel(id: 2, seed: nil)
        for _ in 0..<10 { await Task.yield() }
        #expect(capabilities.invocations == 2)
    }
}

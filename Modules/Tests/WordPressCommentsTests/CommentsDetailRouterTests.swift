import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentsDetailRouterTests {
    @Test func reviewSessionsAreIndependentOfHostAndPreviousSession() throws {
        let router = makeRouter(capabilities: FakeCommentsCapabilities())
        let batch = [makeItem(status: .hold)]
        let first = try #require(router.makeReviewSession(batch: batch))
        first.skip(id: batch[0].id)
        first.close()

        let second = try #require(router.makeReviewSession(batch: batch))
        #expect(first.id != second.id)
        #expect(second.batch.map(\.id) == batch.map(\.id))
        #expect(second.position == 0)
        #expect(second.outcomes.isEmpty)
        #expect(!second.isDismissed)
    }

    @Test func emptyReviewDoesNotCreateSession() {
        let router = makeRouter(capabilities: FakeCommentsCapabilities())
        #expect(router.makeReviewSession(batch: []) == nil)
    }

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

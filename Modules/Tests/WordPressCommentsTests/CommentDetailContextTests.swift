import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentDetailContextTests {
    @Test func makesDetailViewModelWithRequestedIdentityAndSeed() {
        let context = makeDetailContext(capabilities: FakeCommentsCapabilities())
        let seed = makeItem(id: 42, authorName: "Seed author")

        let viewModel = context.makeViewModel(id: 42, seed: seed)

        #expect(viewModel.commentID == 42)
        #expect(viewModel.header?.authorName == "Seed author")
    }

    @Test func makesRendererWithLinkHandler() throws {
        let context = makeDetailContext(capabilities: FakeCommentsCapabilities())

        let renderer = try #require(context.makeRenderer() as? FakeContentRenderer)

        #expect(renderer.onLinkTapped != nil)
    }

    @Test func makeViewModelReusesCapabilityAndRetriesAfterFailure() async {
        let capabilities = FakeCommentsCapabilities()
        capabilities.error = FakeServiceError()
        let context = makeDetailContext(capabilities: capabilities)

        // Resolved while the list loads; the failure is not cached.
        await waitUntil { capabilities.invocations == 1 }
        capabilities.error = nil
        _ = context.makeViewModel(id: 1, seed: nil)
        await waitUntil { capabilities.invocations == 2 }

        // Once known, later detail screens reuse the answer.
        _ = context.makeViewModel(id: 2, seed: nil)
        for _ in 0..<10 { await Task.yield() }
        #expect(capabilities.invocations == 2)
    }
}

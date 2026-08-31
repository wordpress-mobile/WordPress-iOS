import Foundation
import Testing
import WordPressAPI
@testable import WordPressComments

@MainActor
struct CommentsAnalyticsTests {
    @Test func detailViewedFiresOnceOnFirstSuccessfulFetch() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 7, post: 42))
        let spy = SpyCommentsTracker()
        let vm = makeVM(commentID: 7, service: service, tracker: spy)

        await vm.onAppear()
        // A second appearance is a no-op after the first success; the event must
        // not fire twice.
        await vm.onAppear()

        #expect(spy.trackedEvents == [.detailViewed(commentID: 7, postID: 42)])
    }

    @Test func detailViewedDoesNotFireWhenFetchFails() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .failure(FakeServiceError())
        let spy = SpyCommentsTracker()
        let vm = makeVM(commentID: 7, service: service, tracker: spy)

        await vm.onAppear()

        #expect(spy.trackedEvents.isEmpty)
    }
}

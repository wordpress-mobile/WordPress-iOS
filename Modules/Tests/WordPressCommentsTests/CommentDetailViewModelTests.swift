import Foundation
import Testing
import WordPressAPI
@testable import WordPressComments

@MainActor
struct CommentDetailViewModelTests {
    @Test func seededHeaderPaintsBeforeFetch() {
        let seed = makeItem(id: 1, authorName: "Ada", post: 42, status: .hold)
        let vm = makeVM(seed: seed, service: FakeCommentsService())

        #expect(vm.header?.authorName == "Ada")
        #expect(vm.header?.postID == 42)
        #expect(vm.header?.status == .pending)
    }

    @Test func seedlessHeaderIsNilUntilFetch() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved))
        let vm = makeVM(seed: nil, service: service)

        #expect(vm.header == nil)

        await vm.onAppear()
        #expect(vm.header?.status == .approved)
    }

    @Test func capabilityTrueFetchesEditContext() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, editContext: true))
        let capabilities = FakeCommentsCapabilities()
        capabilities.canModerate = true
        let vm = makeVM(service: service, capabilities: capabilities)

        await vm.onAppear()

        #expect(service.fetchCommentInvocations.last?.allowsEditContext == true)
    }

    @Test func capabilityFalseFetchesViewContext() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1))
        let capabilities = FakeCommentsCapabilities()
        capabilities.canModerate = false
        let vm = makeVM(service: service, capabilities: capabilities)

        await vm.onAppear()

        #expect(service.fetchCommentInvocations.last?.allowsEditContext == false)
    }

    @Test func duplicateAppearanceDoesNotRefetchAfterSuccess() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1))
        let vm = makeVM(service: service)

        await vm.onAppear()
        await vm.onAppear()

        #expect(service.fetchCommentInvocations.count == 1)
    }

    @Test func duplicateAppearanceDoesNotStartConcurrentFetch() async {
        let service = BlockingCommentsService()
        let vm = makeVM(service: service)

        async let firstAppearance: Void = vm.onAppear()
        while service.fetchCommentInvocations.isEmpty { await Task.yield() }
        await vm.onAppear()

        #expect(service.fetchCommentInvocations.count == 1)
        service.resolveFetch(callIndex: 0, with: makeDetail(id: 1))
        await firstAppearance
    }

    @Test func failedFetchShowsFailureAndRetryLoadsDetail() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .failure(FakeServiceError())
        let vm = makeVM(service: service)

        await vm.onAppear()
        #expect(vm.content == .failed)

        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved))
        await vm.retry()

        #expect(vm.content == .loaded(makeDetail(id: 1, status: .approved)))
    }

    @Test func parentPreviewLoadedForReply() async {
        let service = FakeCommentsService()
        service.fetchCommentResultsByID = [
            1: .success(makeDetail(id: 1, parent: 5)),
            5: .success(makeDetail(id: 5, status: .approved))
        ]
        let vm = makeVM(service: service)

        await vm.onAppear()

        #expect(vm.parentPreview?.id == 5)
        #expect(service.fetchCommentInvocations.contains { $0.id == 5 && $0.allowsEditContext == false })
    }

    @Test func parentFetchFailureHidesStrip() async {
        let service = FakeCommentsService()
        service.fetchCommentResultsByID = [1: .success(makeDetail(id: 1, parent: 5))]
        let vm = makeVM(service: service)

        await vm.onAppear()

        #expect(vm.parentPreview == nil)
    }
}

import Foundation
import XCTest
import Nimble

@testable import WordPress

class PostNoticeViewModelTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDown() {
        context = nil
        contextManager = nil

        super.tearDown()
    }

    func testCreatesNoticeWithFailureMessageForFailedPublishedPosts() {
        // Given
        let post = PostBuilder(context)
            .published()
            .with(title: "Darby Ritchie")
            .with(remoteStatus: .failed)
            .confirmedAutoUpload()
            .build()

        // When
        let notice = PostNoticeViewModel(post: post).notice

        // Then
        expect(notice.title).to(equal(PostNoticeViewModel.FailureTitles.postWillBePublished))
        expect(notice.message).to(equal(post.postTitle))
        expect(notice.actionTitle).to(equal(PostNoticeViewModel.FailureActionTitles.cancel))
    }

    func testFailedPublishedPostsCancelButtonWillCancelAutoUpload() {
        // Given
        let post = PostBuilder(context)
            .published()
            .with(title: "Dr. Ed Simonis")
            .with(remoteStatus: .failed)
            .confirmedAutoUpload()
            .build()
        try! context.save()

        let postCoordinator = MockPostCoordinator()
        let notice = PostNoticeViewModel(post: post, postCoordinator: postCoordinator).notice

        // When
        notice.actionHandler?(true)

        // Then
        expect(postCoordinator.cancelAutoUploadOfInvocations).to(equal(1))
    }

    private final class MockPostCoordinator: PostCoordinator {
        private(set) var cancelAutoUploadOfInvocations: Int = 0

        override func cancelAutoUploadOf(_ post: AbstractPost) {
            cancelAutoUploadOfInvocations += 1
        }
    }
}

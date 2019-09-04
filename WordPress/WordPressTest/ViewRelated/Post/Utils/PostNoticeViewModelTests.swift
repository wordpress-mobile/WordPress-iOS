import Foundation
import XCTest
import Nimble

@testable import WordPress

private typealias FailureActionTitles = PostNoticeViewModel.FailureActionTitles
private typealias FailureTitles = PostNoticeViewModel.FailureTitles

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

    func testNoticesToBeShownAfterFailingToUploadPosts() {
        struct Expectation {
            let scenario: String
            let post: Post
            let title: String
            let actionTitle: String
        }

        // Arrange
        let expectations: [Expectation] = [
            Expectation(
                scenario: "Local draft",
                post: PostBuilder(context).with(title: "molestiae").with(remoteStatus: .failed).drafted().build(),
                title: FailureTitles.draftWillBeUploaded,
                actionTitle: FailureActionTitles.retry
            ),
            Expectation(
                scenario: "Local published draft with confirmed auto-upload",
                post: PostBuilder(context).with(title: "dolores").published().with(remoteStatus: .failed).confirmedAutoUpload().build(),
                title: FailureTitles.postWillBePublished,
                actionTitle: FailureActionTitles.cancel
            ),
        ]

        expectations.forEach { expectation in
            // Act
            let notice = PostNoticeViewModel(post: expectation.post).notice

            // Assert
            expect({
                guard notice.title == expectation.title else {
                    return .failed(reason: "Scenario “\(expectation.scenario)” failed. Expected notice.title to equal ”\(expectation.title)”. Actual is ”\(notice.title).")
                }
                guard notice.actionTitle == expectation.actionTitle else {
                    return .failed(reason: "Scenario ”\(expectation.scenario)” failed. Expected notice.actionTitle to equal ”\(expectation.actionTitle)”. Actual is ”\(String(describing: notice.actionTitle)).")
                }
                guard notice.message == expectation.post.postTitle else {
                    return .failed(reason: "Scenario ”\(expectation.scenario)” failed. Expected notice.message to equal ”\(String(describing: expectation.post.postTitle))”. Actual is ”\(String(describing: notice.message)).")
                }

                return .succeeded
            }).to(succeed())
        }
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

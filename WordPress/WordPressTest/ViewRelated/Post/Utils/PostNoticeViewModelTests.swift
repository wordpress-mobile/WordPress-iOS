import Foundation
import XCTest
import Nimble

@testable import WordPress

private typealias FailureActionTitles = PostNoticeViewModel.FailureActionTitles

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
                post: createPost(.draft),
                title: PostAutoUploadMessages.draftWillBeUploaded,
                actionTitle: FailureActionTitles.retry
            ),
            Expectation(
                scenario: "Draft with confirmed local changes",
                post: createPost(.draft, hasRemote: true),
                title: PostAutoUploadMessages.draftWillBeUploaded,
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Local published draft",
                post: createPost(.publish),
                title: PostAutoUploadMessages.postWillBePublished,
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Published post with confirmed local changes",
                post: createPost(.publish, hasRemote: true),
                title: PostAutoUploadMessages.postWillBePublished,
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Locally scheduled post",
                post: createPost(.scheduled),
                title: i18n("We'll schedule your post when your device is back online."),
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Scheduled post with confirmed local changes",
                post: createPost(.scheduled, hasRemote: true),
                title: i18n("We'll schedule your post when your device is back online."),
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Post with at least 1 auto upload to publish attempt",
                post: createPost(.publish, hasRemote: true, autoUploadAttemptsCount: 2),
                title: i18n("We couldn't publish this post, but we'll try again later."),
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Post with the maximum number of auto upload to publish attempts",
                post: createPost(.publish, hasRemote: true, autoUploadAttemptsCount: 3),
                title: i18n("We couldn't complete this action, and didn't publish this post."),
                actionTitle: FailureActionTitles.retry
            ),
            Expectation(
                scenario: "Draft with at least 1 auto upload attempt",
                post: createPost(.draft, hasRemote: true, autoUploadAttemptsCount: 2),
                title: i18n("We couldn't complete this action, but we'll try again later."),
                actionTitle: FailureActionTitles.cancel
            ),
            Expectation(
                scenario: "Draft with the maximum number of auto upload attempts",
                post: createPost(.draft, hasRemote: true, autoUploadAttemptsCount: 3),
                title: i18n("We couldn't complete this action."),
                actionTitle: FailureActionTitles.retry
            ),
        ]

        expectations.forEach { expectation in
            // Act
            let notice = PostNoticeViewModel(post: expectation.post).notice

            // Assert
            expect({
                guard notice.title == expectation.title else {
                    return .failed(reason: "Scenario “\(expectation.scenario)” failed. Expected notice.title to equal ”\(expectation.title)”. Actual is ”\(notice.title)”.")
                }
                guard notice.actionTitle == expectation.actionTitle else {
                    return .failed(reason: "Scenario ”\(expectation.scenario)” failed. Expected notice.actionTitle to equal ”\(expectation.actionTitle)”. Actual is ”\(String(describing: notice.actionTitle))”.")
                }
                guard notice.message == expectation.post.postTitle else {
                    return .failed(reason: "Scenario ”\(expectation.scenario)” failed. Expected notice.message to equal ”\(String(describing: expectation.post.postTitle))”. Actual is ”\(String(describing: notice.message))”.")
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

    func testFailedPublishedUploadedDraftPostsPublishButtonWillMarkForAutoUpload() {
        // Given
        let context = ContextManager.shared.mainContext
        let post = PostBuilder(context)
            .drafted()
            .with(title: "I've been drafted!")
            .withRemote()
            .with(remoteStatus: .sync)
            .build()
        try! context.save()

        let postCoordinator = MockPostCoordinator()
        let notice = PostNoticeViewModel(post: post, postCoordinator: postCoordinator).notice

        // When
        notice.actionHandler?(true)

        // Then
        expect(post.shouldAttemptAutoUpload).to(beTrue())
    }


    private func createPost(_ status: BasePost.Status, hasRemote: Bool = false, autoUploadAttemptsCount: Int = 0) -> Post {
        var builder = PostBuilder(context)
            .with(title: UUID().uuidString)
            .with(status: status)
            .with(remoteStatus: .failed)

        if hasRemote {
            builder = builder.withRemote()
        }

        builder = builder.with(autoUploadAttemptsCount: autoUploadAttemptsCount)

        builder = builder.confirmedAutoUpload()

        return builder.build()
    }

    private final class MockPostCoordinator: PostCoordinator {
        private(set) var cancelAutoUploadOfInvocations: Int = 0

        override func cancelAutoUploadOf(_ post: AbstractPost) {
            cancelAutoUploadOfInvocations += 1
        }

        override func save(_ postToSave: AbstractPost, automatedRetry: Bool = false, forceDraftIfCreating: Bool = false, defaultFailureNotice: Notice? = nil, completion: ((Result<AbstractPost>) -> ())? = nil) {

        }
    }
}

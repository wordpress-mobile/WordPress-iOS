import Foundation
import XCTest
import Nimble

@testable import WordPress

private typealias FailureActionTitles = PostNoticeViewModel.FailureActionTitles

class PostNoticeViewModelTests: XCTestCase {
    private struct Scenario {
        let name: String
        let post: AbstractPost
        let isInternetReachable: Bool
        let expectation: Expectation

        struct Expectation {
            let title: String
            let actionTitle: String
            let postTitle: String?
        }

        init(name: String, page: Page, isInternetReachable: Bool, expectedTitle: String, expectedActionTitle: String) {
            self.init(
                name: name,
                abstractPost: page,
                isInternetReachable: isInternetReachable,
                expectedTitle: expectedTitle,
                expectedActionTitle: expectedActionTitle)
        }

        init(name: String, post: Post, isInternetReachable: Bool, expectedTitle: String, expectedActionTitle: String) {
            self.init(
                name: name,
                abstractPost: post,
                isInternetReachable: isInternetReachable,
                expectedTitle: expectedTitle,
                expectedActionTitle: expectedActionTitle)
        }

        private init(name: String, abstractPost: AbstractPost, isInternetReachable: Bool, expectedTitle: String, expectedActionTitle: String) {
            self.name = name
            self.post = abstractPost
            self.isInternetReachable = isInternetReachable
            self.expectation = Expectation(title: expectedTitle, actionTitle: expectedActionTitle, postTitle: post.postTitle)
        }
    }

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    // MARK: - Test Setup

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

    // MARK: - Expectations

    private func verify(_ scenario: Scenario) -> Nimble.ToSucceedResult {
        let expectation = scenario.expectation
        let notice = PostNoticeViewModel(post: scenario.post, isInternetReachable: scenario.isInternetReachable).notice

        guard notice.title == expectation.title else {
            return .failed(reason: "Scenario “\(scenario.name)” failed. Expected notice.title to equal ”\(expectation.title)”. Actual is ”\(notice.title)”.")
        }
        guard notice.actionTitle == expectation.actionTitle else {
            return .failed(reason: "Scenario ”\(scenario.name)” failed. Expected notice.actionTitle to equal ”\(expectation.actionTitle)”. Actual is ”\(String(describing: notice.actionTitle))”.")
        }
        guard notice.message == expectation.postTitle else {
            return .failed(reason: "Scenario ”\(scenario.name)” failed. Expected notice.message to equal ”\(String(describing: expectation.postTitle))”. Actual is ”\(String(describing: notice.message))”.")
        }

        return .succeeded
    }

    // MARK: - Post Offline Notices: First Try

    func testNoticesToBeShownAfterFailingToUploadPostsOnFirstTry() {

        // Arrange
        let scenarios: [Scenario] = [
            Scenario(
                name: "Save draft while offline, first try",
                post: createPost(.draft),
                isInternetReachable: false,
                expectedTitle: i18n("We'll save your draft when your device is back online."),
                expectedActionTitle: FailureActionTitles.retry
            ),
            Scenario(
                name: "Private Publish while offline, first try",
                post: createPost(.publishPrivate),
                isInternetReachable: false,
                expectedTitle: i18n("We'll publish your private post when your device is back online."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
            Scenario(
                name: "Publish while offline, first try",
                post: createPost(.publish),
                isInternetReachable: false,
                expectedTitle: i18n("We'll publish the post when your device is back online."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
            Scenario(
                name: "Schedule while offline, first try",
                post: createPost(.scheduled, hasRemote: true),
                isInternetReachable: false,
                expectedTitle: i18n("We'll schedule your post when your device is back online."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
            Scenario(
                name: "Submit for review while offline, first try",
                post: createPost(.pending, hasRemote: true),
                isInternetReachable: false,
                expectedTitle: i18n("We'll submit your post for review when your device is back online."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
        ]

        scenarios.forEach { scenario in
            expect({ self.verify(scenario) }).to(succeed())
        }
    }

    // MARK: - Post Offline Notices: Retry

    func testNoticesToBeShownAfterFailingToUploadPostsOnRetry() {

        // Arrange
        let scenarios: [Scenario] = [
            Scenario(
                name: "Save draft while offline, retry",
                post: createPost(.draft, autoUploadAttemptsCount: 1),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't complete this action, but we'll try again later."),
                expectedActionTitle: FailureActionTitles.retry
            ),
            Scenario(
                name: "Private Publish while offline, retry",
                post: createPost(.publishPrivate, hasRemote: true, autoUploadAttemptsCount: 1),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't publish this private post, but we'll try again later."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
            Scenario(
                name: "Publish while offline, retry",
                post: createPost(.publish, hasRemote: true, autoUploadAttemptsCount: 2),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't publish this post, but we'll try again later."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
            Scenario(
                name: "Schedule while offline, retry",
                post: createPost(.scheduled, hasRemote: true, autoUploadAttemptsCount: 1),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't schedule this post, but we'll try again later."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
            Scenario(
                name: "Submit for review while offline, retry",
                post: createPost(.pending, hasRemote: true, autoUploadAttemptsCount: 2),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't submit this post for review, but we'll try again later."),
                expectedActionTitle: FailureActionTitles.cancel
            ),
        ]

        scenarios.forEach { scenario in
            expect({ self.verify(scenario) }).to(succeed())
        }
    }

    // MARK: - Post Offline Notices: No Retries

    func testNoticesToBeShownAfterFailingToUploadPostsLastTry() {

        // Arrange
        let scenarios: [Scenario] = [
            Scenario(
                name: "Save draft while offline, last try",
                post: createPost(.draft, hasRemote: true, autoUploadAttemptsCount: 3),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't complete this action."),
                expectedActionTitle: FailureActionTitles.retry
            ),
            Scenario(
                name: "Private Publish while offline, last try",
                post: createPost(.publishPrivate, hasRemote: true, autoUploadAttemptsCount: 3),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't complete this action, and didn't publish this private post."),
                expectedActionTitle: FailureActionTitles.retry
            ),
            Scenario(
                name: "Publish while offline, last try",
                post: createPost(.publish, hasRemote: true, autoUploadAttemptsCount: 3),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't complete this action, and didn't publish this post."),
                expectedActionTitle: FailureActionTitles.retry
            ),
            Scenario(
                name: "Schedule while offline, last try",
                post: createPost(.scheduled, hasRemote: true, autoUploadAttemptsCount: 3),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't complete this action, and didn't schedule this post."),
                expectedActionTitle: FailureActionTitles.retry
            ),
            Scenario(
                name: "Submit for review while offline, last try",
                post: createPost(.pending, hasRemote: true, autoUploadAttemptsCount: 3),
                isInternetReachable: false,
                expectedTitle: i18n("We couldn't complete this action, and didn't submit this post for review."),
                expectedActionTitle: FailureActionTitles.retry
            ),
        ]

        scenarios.forEach { scenario in
            expect({ self.verify(scenario) }).to(succeed())
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

        override func save(_ postToSave: AbstractPost, automatedRetry: Bool = false, forceDraftIfCreating: Bool = false, defaultFailureNotice: Notice? = nil, completion: ((Result<AbstractPost, Error>) -> ())? = nil) {

        }
    }
}

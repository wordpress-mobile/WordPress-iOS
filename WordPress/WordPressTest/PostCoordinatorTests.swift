import UIKit
import XCTest
import Nimble
import WordPressFlux

@testable import WordPress

class PostCoordinatorTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
        TestAnalyticsTracker.setup()
    }

    override func tearDown() {
        super.tearDown()
        TestAnalyticsTracker.tearDown()
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testDoNotUploadAPostWithFailedMedia() {
        let postServiceMock = PostServiceMock()
        let post = PostBuilder(context)
            .with(image: "test.jpeg", status: .failed)
            .with(remoteStatus: .local)
            .build()
        let mediaCoordinatorMock = MediaCoordinatorMock(media: post.media.first!, mediaState: .failed(error: NSError()))
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock, mediaCoordinator: mediaCoordinatorMock)

        postCoordinator.save(post)

        expect(postServiceMock.didCallMarkAsFailedAndDraftIfNeeded).toEventually(beTrue())
        expect(postServiceMock.didCallUploadPost).to(beFalse())
    }

    func testUploadAPostWithNoFailedMedia() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg")
            .build()

        postCoordinator.save(post)

        expect(postServiceMock.didCallUploadPost).to(beTrue())
    }

    func testEventuallyMarkThePostRemoteStatusAsUploading() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg")
            .build()

        postCoordinator.save(post)

        expect(post.remoteStatus).toEventually(equal(.pushing))
    }

    func testAttemptCountIsIncrementedAfterFailingToAutomaticallyUpload() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context).build()

        postCoordinator.save(post, automatedRetry: true)

        expect(post.autoUploadAttemptsCount).to(equal(1))
    }

    func testAttemptCountIsResetWhenNotAutomaticallyUpload() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context).with(autoUploadAttemptsCount: 3).build()

        postCoordinator.save(post, automatedRetry: false)

        expect(post.autoUploadAttemptsCount).to(equal(0))
    }

    func testReturnPostWhenServiceSucceed() {
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context).build()
        postServiceMock.returnPost = post
        var returnedPost: AbstractPost?

        postCoordinator.save(post) { result in
            switch result {
            case .success(let post):
                returnedPost = post
            default:
                break
            }
        }

        expect(returnedPost).toEventuallyNot(beNil())
    }

    func testReturnErrorWhenServiceFails() {
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context).build()
        postServiceMock.returnError = NSError(domain: "", code: 1, userInfo: nil)
        var returnedError: Error?

        postCoordinator.save(post) { result in
            switch result {
            case .error(let error):
                returnedError = error
            default:
                break
            }
        }

        expect(returnedError).toEventuallyNot(beNil())
    }

    func testReturnErrorWhenMediaFails() {
        let postServiceMock = PostServiceMock()
        let post = PostBuilder(context)
            .with(image: "test.jpeg", status: .failed)
            .with(remoteStatus: .local)
            .build()
        let mediaCoordinatorMock = MediaCoordinatorMock(media: post.media.first!, mediaState: .failed(error: NSError()))
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock, mediaCoordinator: mediaCoordinatorMock)
        var returnedError: Error?

        postCoordinator.save(post) { result in
            switch result {
            case .error(let error):
                returnedError = error
            default:
                break
           }
        }

        expect(returnedError).toEventuallyNot(beNil())
    }

    func testResumeWillAutoSaveUnconfirmedExistingPosts() {
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        _ = PostBuilder(context)
            .withRemote()
            .with(status: .draft)
            .with(remoteStatus: .failed)
            .supportsWPComAPI()
            .build()
        try! context.save()

        postCoordinator.resume()

        expect(postServiceMock.didCallAutoSave).toEventually(beTrue())
    }

    func testResumeWillUploadUnconfirmedPublishedPostsAsDraftsOnSelfHostedSites() {
        // Arrange
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        _ = PostBuilder(context)
            .with(status: .publish)
            .with(remoteStatus: .failed)
            .with(title: "Ipsam nihil")
            .build()
        try! context.save()

        // Act
        postCoordinator.resume()

        // Assert
        expect(postServiceMock.didCallUploadPost).toEventually(beTrue())
        expect(postServiceMock.lastUploadPostInvocation).toEventuallyNot(beNil())

        let invocation = postServiceMock.lastUploadPostInvocation!
        expect(invocation.post.postTitle).to(equal("Ipsam nihil"))
        expect(invocation.forceDraftIfCreating).to(beTrue())
    }

    func testCancelAutoUploadOfAPost() {
        let post = PostBuilder(context).confirmedAutoUpload().build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.cancelAutoUploadOf(post)

        expect(post.shouldAttemptAutoUpload).to(beFalse())
    }

    func testCancelAutoUploadDoNotChangePostStatusToDraftWhenPostHasRemote() {
        let post = PostBuilder(context)
            .withRemote()
            .with(status: .publish)
            .with(remoteStatus: .failed)
            .build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.cancelAutoUploadOf(post)

        expect(post.status).to(equal(.publish))
    }

    func testChangeDraftToPublishWhenPublishing() {
        let post = PostBuilder(context).drafted().build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.publish(post)

        expect(post.status).to(equal(.publish))
    }

    func testDoNotChangeDateCreatedForAScheduledPost() {
        let post = PostBuilder(context).with(dateCreated: Date(timeIntervalSince1970: 50)).scheduled().build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.publish(post)

        expect(post.date_created_gmt).to(equal(Date(timeIntervalSince1970: 50)))
    }

    func testSetShouldAttemptAutoUploadToTrue() {
        let post = PostBuilder(context).drafted().build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.publish(post)

        expect(post.shouldAttemptAutoUpload).to(beTrue())
    }

    func testCallPostCoordinatorToSaveAPost() {
        let post = PostBuilder(context).drafted().build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.publish(post)

        expect(postServiceMock.didCallUploadPost).to(beTrue())
    }

    func testChangePostToDraftWhenMovingToDraft() {
        let post = PostBuilder(context).published().build()
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.moveToDraft(post)

        expect(post.status).to(equal(.draft))
    }

    func testTracksAutoUploadPostInvoked() {
        // Arrange
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let interactor = PostAutoUploadInteractor()
        let post = PostBuilder(context)
            .withRemote()
            .with(status: .draft)
            .with(remoteStatus: .failed)
            .supportsWPComAPI()
            .build()
        try! context.save()

        let expectedAction = interactor.autoUploadAction(for: post)

        // Act
        postCoordinator.resume()
        guard let status = post.status else {
            return
        }

        // Assert
        expect(TestAnalyticsTracker.tracked.count).toEventually(equal(1))
        let trackEvent = TestAnalyticsTracker.tracked.first
        expect(trackEvent?.stat).toEventually(equal(WPAnalyticsStat.autoUploadPostInvoked))

        let propertyAction = trackEvent?.properties["upload_action"] as? String
        expect(propertyAction).toEventually(equal(expectedAction.rawValue))

        let propertyStatus = trackEvent?.properties["post_status"] as? String
        expect(propertyStatus).toEventually(equal(status.rawValue))
    }

    func testSavingSuccessfullyWillDispatchASuccessNotice() {
        // Arrange
        let post = PostBuilder(context)
            .with(title: "Sint dolorem quo")
            .with(status: .publish)
            .with(remoteStatus: .local)
            .build()

        let postServiceMock = PostServiceMock(managedObjectContext: context)
        postServiceMock.returnPost = post

        let actionDispatcherFacadeMock = ActionDispatcherFacadeMock()

        let postCoordinator = PostCoordinator(mainService: postServiceMock,
                                              backgroundService: postServiceMock,
                                              actionDispatcherFacade: actionDispatcherFacadeMock)

        // Act
        var result: Result<AbstractPost>? = nil
        waitUntil(timeout: 2) { done in
            postCoordinator.save(post) { aResult in
                result = aResult
                done()
            }
        }

        // Assert
        expect(result).notTo(beNil())
        expect(actionDispatcherFacadeMock.dispatchedActions).toEventuallyNot(beEmpty())

        guard case let NoticeAction.post(notice)? = actionDispatcherFacadeMock.dispatchedActions.first else {
            assertionFailure("The action should be a NoticeAction")
            return
        }

        expect(notice.feedbackType).to(equal(.success))
        expect(notice.message).to(contain("Sint dolorem quo"))
    }

    func testFailingToSaveWillDispatchAFailedNotice() {
        // Arrange
        let post = PostBuilder(context)
            .with(title: "Sit neque qui")
            .with(status: .publish)
            .with(remoteStatus: .local)
            .build()

        let postServiceMock = PostServiceMock(managedObjectContext: context)
        postServiceMock.returnError = NSError(domain: "", code: 1, userInfo: nil)

        let actionDispatcherFacadeMock = ActionDispatcherFacadeMock()

        let postCoordinator = PostCoordinator(mainService: postServiceMock,
                                              backgroundService: postServiceMock,
                                              actionDispatcherFacade: actionDispatcherFacadeMock)

        // Act
        var result: Result<AbstractPost>? = nil
        waitUntil(timeout: 2) { done in
            postCoordinator.save(post) { aResult in
                result = aResult
                done()
            }
        }

        // Assert
        expect(result).notTo(beNil())
        expect(actionDispatcherFacadeMock.dispatchedActions).toEventuallyNot(beEmpty())

        guard case let NoticeAction.post(notice)? = actionDispatcherFacadeMock.dispatchedActions.first else {
            assertionFailure("The action should be a NoticeAction")
            return
        }

        expect(notice.feedbackType).to(equal(.error))
        expect(notice.message).to(contain("Sit neque qui"))
    }

    func testFailingToSaveBecauseOfMediaErrorsWillDispatchAFailedNotice() {
        // Arrange
        let post = PostBuilder(context)
            .with(title: "Ipsa aliquam")
            .with(image: "test.jpeg", status: .failed)
            .with(status: .publish)
            .with(remoteStatus: .local)
            .build()

        let mediaCoordinatorMock = MediaCoordinatorMock(media: post.media.first!, mediaState: .failed(error: NSError()))
        let postServiceMock = PostServiceMock(managedObjectContext: context)
        let actionDispatcherFacadeMock = ActionDispatcherFacadeMock()

        let postCoordinator = PostCoordinator(mainService: postServiceMock,
                                              backgroundService: postServiceMock,
                                              mediaCoordinator: mediaCoordinatorMock,
                                              actionDispatcherFacade: actionDispatcherFacadeMock)

        // Act
        var result: Result<AbstractPost>? = nil
        waitUntil(timeout: 2) { done in
            postCoordinator.save(post) { aResult in
                result = aResult
                done()
            }
        }

        // Assert
        expect(result).notTo(beNil())
        expect(actionDispatcherFacadeMock.dispatchedActions).toEventuallyNot(beEmpty())

        guard case let NoticeAction.post(notice)? = actionDispatcherFacadeMock.dispatchedActions.first else {
            assertionFailure("The action should be a NoticeAction")
            return
        }

        expect(notice.feedbackType).to(equal(.error))
        expect(notice.message).to(contain("Ipsa aliquam"))
    }

    func testFailingToSaveBecauseOfMediaErrorsWillWillCallCompletionBlockOnlyOnce() {
        // Arrange
        let post = PostBuilder(context)
            .with(image: "test.jpeg", status: .failed)
            .with(image: "test-002.jpeg", status: .failed)
            .build()

        let onUpdateParameters = post.media.reduce(into: [Media: MediaCoordinator.MediaState]()) { dict, media in
            dict[media] = MediaCoordinator.MediaState.failed(error: NSError())
        }
        let mediaCoordinatorMock = MediaCoordinatorMock(onUpdateParameters: onUpdateParameters)

        let postServiceMock = PostServiceMock(managedObjectContext: context)

        let postCoordinator = PostCoordinator(mainService: postServiceMock,
                                              backgroundService: postServiceMock,
                                              mediaCoordinator: mediaCoordinatorMock)

        // Act
        var results = [Result<AbstractPost>]()
        waitUntil(timeout: 2) { done in
            postCoordinator.save(post) { aResult in
                results.append(aResult)
                done()
            }
        }

        // Assert
        expect(results).to(haveCount(1))
    }
}

private class PostServiceMock: PostService {
    struct UploadPostInvocation {
        let post: AbstractPost
        let forceDraftIfCreating: Bool
    }

    private(set) var didCallMarkAsFailedAndDraftIfNeeded = false
    private(set) var didCallAutoSave = false

    private(set) var lastUploadPostInvocation: UploadPostInvocation?
    var didCallUploadPost: Bool {
        return lastUploadPostInvocation != nil
    }

    var returnPost: AbstractPost?
    var returnError: Error?

    override func uploadPost(_ post: AbstractPost, forceDraftIfCreating: Bool, success: ((AbstractPost) -> Void)?, failure: @escaping (Error?) -> Void) {
        lastUploadPostInvocation = UploadPostInvocation(post: post, forceDraftIfCreating: forceDraftIfCreating)

        if let post = returnPost {
            post.remoteStatus = .sync
            success?(post)
        }
        if let error = returnError {
            post.remoteStatus = .failed
            failure(error)
        }
    }

    override func autoSave(_ post: AbstractPost, success: ((AbstractPost, String) -> Void)?, failure: @escaping (Error?) -> Void) {
        didCallAutoSave = true
    }

    override func markAsFailedAndDraftIfNeeded(post: AbstractPost) {
        didCallMarkAsFailedAndDraftIfNeeded = true
    }
}

private class MediaCoordinatorMock: MediaCoordinator {
    private var onUpdateParameters = [Media: MediaState]()

    init(media: Media, mediaState: MediaState) {
        onUpdateParameters[media] = mediaState
    }

    init(onUpdateParameters: [Media: MediaState]) {
        self.onUpdateParameters = onUpdateParameters
    }

    override func addObserver(_ onUpdate: @escaping MediaCoordinator.ObserverBlock, for media: Media? = nil) -> UUID {
        return UUID()
    }

    override func addObserver(_ onUpdate: @escaping MediaCoordinator.ObserverBlock, forMediaFor post: AbstractPost) -> UUID {
        DispatchQueue.main.async {
            self.onUpdateParameters.forEach { media, mediaState in
                onUpdate(media, mediaState)
            }
        }
        return UUID()
    }

    override func retryMedia(_ media: Media, automatedRetry: Bool = false, analyticsInfo: MediaAnalyticsInfo? = nil) {
        // noop
    }
}

private class ActionDispatcherFacadeMock: ActionDispatcherFacade {
    private(set) var dispatchedActions = [Action]()

    override func dispatch(_ action: Action) {
        dispatchedActions.append(action)
    }
}

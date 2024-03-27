import XCTest
import OHHTTPStubs

@testable import WordPress

@MainActor
class PostCoordinatorSyncTests: CoreDataTestCase {
    private var blog: Blog!
    private var mediaCoordinator: MediaCoordinator!
    private var coordinator: PostCoordinator!

    override func setUpWithError() throws {
        try super.setUpWithError()

        blog = BlogBuilder(mainContext)
            .with(dotComID: 80511)
            .withAnAccount()
            .build()
        try mainContext.save()

        mediaCoordinator = MediaCoordinator(coreDataStack: contextManager)
        coordinator = PostCoordinator(mediaCoordinator: mediaCoordinator, coreDataStack: contextManager, isSyncPublishingEnabled: true)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    /// Scenario: user created and saved a new draft post with one image block
    /// (without waiting for upload to finish).
    func testSyncNewDraftWithImageBlock() throws {
        // GIVEN a draft post
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043
        post.postTitle = "title-a"

        // GIVEN a post with a image block with media that needs upload
        let media = MediaBuilder(mainContext).build()
        media.remoteStatus = .failed
        media.blog = post.blog
        media.mediaType = .image
        media.filename = "test-image.jpg"
        media.absoluteLocalURL = try MediaImageServiceTests.makeLocalURL(forResource: "test-image", fileExtension: "jpg")

        // important otherwise MediaService will use temporary objectID and fail
        try mainContext.save()

        let revision1 = post._createRevision()
        revision1.postTitle = "title-b"
        revision1.media = [media]
        let uploadID = media.gutenbergUploadID
        revision1.content = "<!-- wp:image {\"id\":\(uploadID),\"sizeSlug\":\"large\"} -->\n<figure class=\"wp-block-image size-large\"><img src=\"file:///path/thumbnail-15.jpeg\" class=\"wp-image-\(uploadID)\"/></figure>\n<!-- /wp:image -->"

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            let content = request.getBodyParameters()?["content"] as? String
            XCTAssertNotNil(content)

            var mock = WordPressComPost.mock
            mock.content = content
            return try! HTTPStubsResponse(value: mock, statusCode: 201)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/media/new")) { request in
            HTTPStubsResponse(data: mediaResponse.data(using: .utf8)!, statusCode: 202, headers: [:])
        }

        // WHEN
        let expectation = self.expectation(forNotification: .postCoordinatorDidFinishSync, object: coordinator)
        coordinator.setNeedsSync(for: revision1)
        wait(for: [expectation], timeout: 0.5)

        // THEN image block was updated
        XCTAssertEqual(post.content, "<!-- wp:image {\"id\":1236,\"sizeSlug\":\"large\"} -->\n<figure class=\"wp-block-image size-large\"><img src=\"https://example.files.wordpress.com/2024/03/img_0005-1-1.jpg\" class=\"wp-image-1236\"/></figure>\n<!-- /wp:image -->")

        // THEN revisions were uploaded
        XCTAssertFalse(post.hasRevision())
    }

    /// Scenario: user creates and saves a draft and terminates the app before
    /// the sync engine is able to complete sync.
    func testScheduleSync() {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post._createRevision()
        revision1.postTitle = "title-b"
        revision1.content = "content-a"
        revision1.isSyncNeeded = true

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        // WHEN
        let expectation = self.expectation(forNotification: .postCoordinatorDidFinishSync, object: coordinator) { notification in
            guard let operation = notification.userInfo?[PostCoordinator.operationUserInfoKey] as? PostCoordinator.SyncOperation else {
                XCTFail("Missing user info")
                return false
            }
            XCTAssertEqual(operation.post, post)
            XCTAssertEqual(operation.revision, revision1)
            return true
        }
        expectation.expectedFulfillmentCount = 1

        coordinator.scheduleSync()
        wait(for: [expectation], timeout: 0.5)

        // THEN post got synced
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }

    /// Scenario: sync fails with a "not connected to internet" error and the
    /// app quickly re-establishes the connection.
    func testSyncFastRetryOnReachabilityChange() {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post._createRevision()
        revision1.postTitle = "title-b"
        revision1.content = "content-a"
        revision1.isSyncNeeded = true

        // GIVEN a first request that fails with a `.notConnectedToInternet`
        // error and the second one that succedes
        var requestCount = 0
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            requestCount += 1
            switch requestCount {
            case 1:
                return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
            case 2:
                return try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
            default:
                XCTFail("Unexpected number of requests: \(requestCount)")
                return HTTPStubsResponse(error: URLError(.unknown))
            }
        }

        // WHEN
        let expectationSyncFailed = self.expectation(forNotification: .postCoordinatorDidUpdate, object: coordinator) { notification in
            if let coordinator = notification.object as? PostCoordinator,
               coordinator.syncError(for: post) != nil {
                NotificationCenter.default.post(name: .reachabilityChanged, object: nil, userInfo: [Foundation.Notification.reachabilityKey: true])
            }
            return true
        }
        let expectationSyncFinished = self.expectation(forNotification: .postCoordinatorDidFinishSync, object: coordinator)
        coordinator.setNeedsSync(for: revision1)
        wait(for: [expectationSyncFailed, expectationSyncFinished], timeout: 0.5)

        // THEN post got synced
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }
}

private let mediaResponse = """
{
  "media": [
    {
      "ID": 1236,
      "URL": "https://example.files.wordpress.com/2024/03/img_0005-1-1.jpg",
      "guid": "http://example.files.wordpress.com/2024/03/img_0005-1-1.jpg",
      "date": "2024-03-25T18:50:12-04:00",
      "post_ID": 0,
      "author_ID": 34129043,
      "file": "img_0005-1-1.jpg",
      "mime_type": "image/jpeg",
      "extension": "jpg",
      "title": "img_0005-1",
      "caption": "",
      "description": "",
      "alt": "",
      "icon": "https://s1.wp.com/wp-includes/images/media/default.png",
      "size": "701.54 KB",
      "height": 1335,
      "width": 2000
    }
  ]
}
"""

private extension URLRequest {
    func getBodyParameters() -> [String: Any]? {
        guard let data = httpBodyStream?.read(),
              let object = try? JSONSerialization.jsonObject(with: data),
              let parameters = object as? [String: Any] else {
            return nil
        }
        return parameters
    }
}

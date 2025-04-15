import Combine
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPress

@MainActor
class PostCoordinatorTests: CoreDataTestCase {
    private var blog: Blog!
    private var mediaCoordinator: MediaCoordinator!
    private var coordinator: PostCoordinator!
    private var cancellables: [AnyCancellable] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        blog = BlogBuilder(mainContext)
            .with(dotComID: 80511)
            .withAnAccount()
            .build()
        try mainContext.save()

        mediaCoordinator = MediaCoordinator(coreDataStack: contextManager)
        coordinator = PostCoordinator(mediaCoordinator: mediaCoordinator, coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    /// Scenario: save a single revision, it successfully syncs.
    func testSyncSingleSimpleRevision() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.content = "content-a"

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        // WHEN
        coordinator.setNeedsSync(for: revision1)
        try await coordinator.waitForSync(post, to: revision1)

        // THEN post got synced
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }

    /// Scenario: first request fails, second one succeedes.
    func testSyncSingleSimpleRevisionAfterRetry() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.content = "content-a"

        // GIVEN
        var requestCount = 0
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { _ in
            requestCount += 1
            switch requestCount {
            case 1:
                return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
            case 2:
                return try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
            default:
                XCTFail("Unexpected number of requests")
                return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
            }
        }

        // GIVEN
        coordinator.syncRetryDelay = 0.01

        // WHEN
        coordinator.setNeedsSync(for: revision1)
        try await coordinator.waitForSync(post, to: revision1, ignoreErrors: true)

        // THEN post got synced after the retry
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }

    /// Scenario: user saves changes to the post while sync is in progress.
    func testSyncRevisionAddedDuringSync() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post.createRevision()
        revision1.postTitle = "title-a"
        revision1.content = "content-a"

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { _ in
            XCTAssertFalse(Thread.isMainThread)
            DispatchQueue.main.sync {
                let revision2 = revision1.createRevision()
                revision2.postTitle = "title-b"
                self.coordinator.setNeedsSync(for: revision2)
            }

            let response = try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
            response.responseTime = 0.01
            return response
        }

        var isPartialRequestSent = false
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            XCTAssertEqual(request.getBodyParameters()?["title"] as? String, "title-b")
            isPartialRequestSent = true

            var post = WordPressComPost.mock
            post.title = "title-b"
            post.content = "content-a"
            return try! HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN
        coordinator.setNeedsSync(for: revision1)

        try await coordinator.waitForSync(post) { operation in
            operation.revision != revision1 // Must be revision2
        }

        // THEN post got synced after the retry
        XCTAssertTrue(isPartialRequestSent)
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.postTitle, "title-b")
        XCTAssertEqual(post.content, "content-a")
        XCTAssertNil(post.revision)
    }

    /// Scenario: user created and saved a new draft post with one image block
    /// (without waiting for upload to finish).
    func testSyncNewDraftWithImageBlock() async throws {
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

        let revision1 = post.createRevision()
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
        coordinator.setNeedsSync(for: revision1)
        try await coordinator.waitForSync(post, to: revision1)

        // THEN image block was updated
        XCTAssertEqual(post.content, "<!-- wp:image {\"id\":1236,\"sizeSlug\":\"large\"} -->\n<figure class=\"wp-block-image size-large\"><img src=\"https://example.files.wordpress.com/2024/03/img_0005-1-1.jpg\" class=\"wp-image-1236\" /></figure>\n<!-- /wp:image -->")

        // THEN revisions were uploaded
        XCTAssertFalse(post.hasRevision())
    }

    /// Scenario: sync fails with a "not connected to internet" error and the
    /// app quickly re-establishes the connection.
    func testSyncFastRetryOnReachabilityChange() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.content = "content-a"

        try mainContext.save()

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

        // GIVEN a long default retry
        coordinator.syncRetryDelay = 10

        // GIVEN the app quickly restoring connectivity after the first failure
        coordinator.syncEvents.sink {
            if case .finished(_, let result) = $0, case .failure = result {
                NotificationCenter.default.post(name: .reachabilityUpdated, object: nil, userInfo: [Foundation.Notification.reachabilityKey: true])
            }
        }.store(in: &cancellables)

        coordinator.setNeedsSync(for: revision1)
        try await coordinator.waitForSync(post, to: revision1, ignoreErrors: true)

        // THEN post got synced
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }

    /// Scenario: create and save a revision with a failing image upload. Re-open
    /// the editor, delete the image, and try to sync.
    func testSyncRevisionAfterDeletingFailingImageUpload() async throws {
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

        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.media = [media]
        let uploadID = media.gutenbergUploadID
        revision1.content = "<!-- wp:image {\"id\":\(uploadID),\"sizeSlug\":\"large\"} -->\n<figure class=\"wp-block-image size-large\"><img src=\"file:///path/thumbnail-15.jpeg\" class=\"wp-image-\(uploadID)\"/></figure>\n<!-- /wp:image -->"

        // GIVEN
        let expectation = self.expectation(description: "started-media-request")
        stub(condition: isPath("/rest/v1.1/sites/80511/media/new")) { _ in
            let response = HTTPStubsResponse(error: URLError(.unknown))
            expectation.fulfill()
            response.responseTime = 10
            return response
        }

        // WHEN the app sends the request to upload the image
        coordinator.setNeedsSync(for: revision1)
        await fulfillment(of: [expectation], timeout: 2)

        let revision2 = revision1.createRevision()
        revision2.media = []
        revision2.content = "empty"

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { _ in
            try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        coordinator.setNeedsSync(for: revision2)
        try await coordinator.waitForSync(post, to: revision2)

        // THEN post got synced without waiting for the image to be uploaded
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }

    /// Scenario: syncing changes to an existing draft that was permanently deleted.
    func testSyncPermanentlyDeletedPost() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.postID = 974
        post.status = .draft
        post.authorID = 29043
        post.postTitle = "title-b"
        post.content = "content-a"

        let revision1 = post.createRevision()
        revision1.content = "content-b"

        // GIVEN a server where the post was deleted
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { _ in
            return try! HTTPStubsResponse(value: [
                "error": "unknown_post",
                "message": "Unknown post"
            ], statusCode: 404)
        }

        // WHEN
        coordinator.setNeedsSync(for: revision1)
        do {
            try await coordinator.waitForSync(post, to: revision1)
            XCTFail("Expected sync to fail")
        } catch {
            guard let error = error as? PostRepository.PostSaveError,
                  case .deleted = error else {
                return XCTFail("Unexpected error")
            }
        }

        // THEN post got deleted from the database
        XCTAssertNil(post.managedObjectContext)
    }

    func testPauseSyncing() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.content = "content-a"

        // GIVEN
        let expectation = self.expectation(description: "request-sent")
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { _ in
            expectation.fulfill()
            let response = try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
            response.responseTime = 0.05
            return response
        }
        coordinator.setNeedsSync(for: revision1)
        await fulfillment(of: [expectation], timeout: 2)

        // WHEN
        await coordinator.pauseSyncing(for: post)

        // THEN post got synced
        XCTAssertEqual(post.postID, 974)
        XCTAssertNil(post.revision)
    }

    // MARK: - Publish

    /// Scenario: publish a draft post that has unsynced revisions.
    func testPublishDraftPostThatNeedsSyncing() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.authorID = 29043

        let revision1 = post.createRevision()
        revision1.postTitle = "title-a"
        revision1.content = "content-a"

        // WHEN a slug was changes during the current editor session
        let revision2 = revision1.createRevision()
        revision2.wp_slug = "hello"

        // GIVEN
        let expectation = self.expectation(description: "request-sent")
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { _ in
            expectation.fulfill()
            let response = try! HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
            response.responseTime = 0.05
            return response
        }
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            XCTAssertEqual(request.getBodyParameters(), [
                "slug": "hello",
                "status": "publish"
            ])
            var post = WordPressComPost.mock
            post.status = AbstractPost.Status.publish.rawValue
            post.title = "title-a"
            post.content = "content-a"
            post.slug = "hello"
            return try! HTTPStubsResponse(value: post, statusCode: 202)
        }
        coordinator.setNeedsSync(for: revision1)
        await fulfillment(of: [expectation], timeout: 2)

        // WHEN
        try await coordinator.publish(post, options: .init(visibility: .public, password: nil, publishDate: nil))

        // THEN the coordinator wait for the sync to complete and the post to
        // be created and only then sends a parial update to get it published
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .publish)
        XCTAssertEqual(post.postTitle, "title-a")
        XCTAssertEqual(post.content, "content-a")
        XCTAssertEqual(post.wp_slug, "hello")
        XCTAssertNil(post.revision)
        XCTAssertNil(revision1.managedObjectContext)
        XCTAssertNil(revision2.managedObjectContext)
    }

    /// Scenario: publish an existing draft with a blogging ID and with a custom
    /// publicize message, both of which use metadata.
    func testSaveExistingPostPublishWithMetadata() async throws {
        // GIVEN a draft post (synced)
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.postID = 974
        post.authorID = 29043
        post.postTitle = "title-a"
        post.content = "content-a"
        post.bloggingPromptID = "prompt-a"

        // GIVEN an editor revision
        let revision = post.createRevision() as! Post
        revision.publicizeMessage = "message-a"

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            let parameters = request.getBodyParameters() ?? [:]
            XCTAssertEqual(parameters["status"], "publish")
            let metadata = (parameters["metadata"] as? [[String: AnyHashable]]) ?? []
            XCTAssertEqual(Set(metadata), Set([
                [
                    "key": "_wpas_mess",
                    "operation": "update",
                    "value": "message-a"
                ],
                [
                    "key": "_jetpack_blogging_prompt_key",
                    "operation": "update",
                    "value": "prompt-a"
                ]
            ]))
            var post = WordPressComPost.mock
            post.metadata = [
                WordPressComPost.Metadata(id: "752", key: "_wpas_mess", value: "message-a")
            ]
            return try! HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN
        try await coordinator.publish(post, options: .init(visibility: .public, password: nil, publishDate: nil))

        // THEN
        XCTAssertEqual(post.publicizeMessage, "message-a")
        XCTAssertEqual(post.publicizeMessageID, "752")
    }

    // MARK: - Misc

    /// Scenario: app launches and has unsynced revisions.
    func testInitializeSync() async throws {
        // GIVEN a draft post that needs sync
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.postID = 974
        post.authorID = 29043
        post.content = "content-a"

        let revision1 = post.createRevision()
        revision1.content = "content-b"
        revision1.remoteStatus = .syncNeeded

        let revision2 = revision1.createRevision()
        revision2.content = "content-c"
        revision2.remoteStatus = .syncNeeded

        let revision3 = revision2.createRevision()
        revision3.content = "content-d"
        XCTAssertFalse(revision3.isSyncNeeded)

        try mainContext.save()

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            XCTAssertEqual(request.getBodyParameters()?["content"] as? String, "content-c")
            var post = WordPressComPost.mock
            post.content = "content-c"
            return try! HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN
        coordinator.initializeSync()
        try await coordinator.waitForSync(post, to: revision2)

        // THEN
        XCTAssertEqual(post.content, "content-c")
        XCTAssertEqual(post.revision, revision3)
    }

    /// Scenario: the app needs to upload the most recent revision to the server
    /// to generate a preview.
    func testSaveDraftPostChangesImmediately() async throws {
        // GIVEN a draft post with an unsynced revision and a local revision
        // that wasn't commited yet
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.postID = 974
        post.authorID = 29043
        post.content = "content-a"

        let revision1 = post.createRevision()
        revision1.content = "content-b"
        revision1.remoteStatus = .syncNeeded

        let revision2 = revision1.createRevision()
        revision2.content = "content-c"

        try mainContext.save()

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            XCTAssertEqual(request.getBodyParameters()?["content"] as? String, "content-c")
            var post = WordPressComPost.mock
            post.content = "content-c"
            return try! HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN
        try await coordinator.save(post)

        // THEN all changes were synced
        XCTAssertEqual(post.content, "content-c")
        XCTAssertNil(post.revision)
    }

    /// Scenario: the app needs to upload the most recent revision to the server
    /// to generate a preview.
    func testSaveDraftPostChangesImmediatelyFailure() async throws {
        // GIVEN a draft post with an unsynced revision and a local revision
        // that wasn't commited yet
        let post = PostBuilder(mainContext, blog: blog).build()
        post.status = .draft
        post.postID = 974
        post.authorID = 29043
        post.content = "content-a"

        let revision1 = post.createRevision()
        revision1.content = "content-b"
        revision1.remoteStatus = .syncNeeded

        let revision2 = revision1.createRevision()
        revision2.content = "content-c"

        try mainContext.save()

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }

        // WHEN
        do {
            try await coordinator.save(post)
            XCTFail("Expected a failure")
        } catch {
            // Expect an error
        }

        // THEN the revisions are in the same state as before the call to `save()`
        XCTAssertEqual(post.content, "content-a")
        XCTAssertEqual(post.revision, revision1)
        XCTAssertTrue(revision1.isSyncNeeded)
        XCTAssertEqual(revision1.revision, revision2)
        XCTAssertFalse(revision2.isSyncNeeded)
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
    func getBodyParameters() -> [String: AnyHashable]? {
        guard let data = httpBodyStream?.read(),
              let object = try? JSONSerialization.jsonObject(with: data),
              let parameters = object as? [String: AnyHashable] else {
            return nil
        }
        return parameters
    }
}

private extension PostCoordinator {
    func waitForSync(_ post: AbstractPost, to revision: AbstractPost, ignoreErrors: Bool = false, timeout: TimeInterval = 5) async throws {
        var olderRevisionIDs = Set(post.allRevisions.filter(\.isSyncNeeded).map(\.objectID))
        olderRevisionIDs.remove(revision.objectID)
        return try await waitForSync(post, ignoreErrors: ignoreErrors, timeout: timeout) { operation in
            guard !olderRevisionIDs.contains(operation.revision.objectID) else {
                return false // Skip operation for older revisions
            }
            return true
        }
    }

    /// Taps into the coordinator events and waits until the post syncs to the
    /// given revision.
    ///
    /// - warning: If more revisions are added during after the call is made,
    /// it'll still finish.
    ///
    /// - parameter timeout: The default value is 5 seconds.
    /// - parameter handler: Return `true` if the revision matches the one you expected.
    func waitForSync(_ post: AbstractPost, ignoreErrors: Bool = false, timeout: TimeInterval = 5, handler: @escaping (PostCoordinator.SyncOperation) -> Bool) async throws {
        let result = await syncEvents
            .compactMap { event -> Result<Void, Error>? in
                guard case .finished(let operation, let result) = event else {
                    return nil
                }
                if ignoreErrors, case .failure = result {
                    return nil // Ignore intermitent errors
                }
                guard handler(operation) else {
                    return nil
                }
                return result
            }
            .first()
            .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
            .values
            .first { _ in true }

        guard let result else {
            throw URLError(.unknown) // Should never happen
        }
        try result.get()
    }
}

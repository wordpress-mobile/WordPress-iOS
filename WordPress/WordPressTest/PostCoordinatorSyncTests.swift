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

        mediaCoordinator = MediaCoordinator(
            coreDataStack: contextManager)
        coordinator = PostCoordinator(mediaCoordinator: mediaCoordinator, coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    /// Scenario: user created and saved a new draft post with one image block
    /// (without waiting for upload to finish).
    func testHappyPath() async throws {
        // GIVEN a draft post (synced)
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
        revision1.isSyncNeeded = true

        // GIVEN a server where the post was deleted
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

        // WHEN saving the post
        await coordinator.sync(post)

        // THEN image block was updated
        XCTAssertEqual(post.content, "<!-- wp:image {\"id\":1236,\"sizeSlug\":\"large\"} -->\n<figure class=\"wp-block-image size-large\"><img src=\"https://example.files.wordpress.com/2024/03/img_0005-1-1.jpg\" class=\"wp-image-1236\"/></figure>\n<!-- /wp:image -->")

        // THEN revisions were uploaded
        XCTAssertFalse(post.hasRevision())
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

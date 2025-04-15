import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPress

@MainActor
class PostRepositorySaveTests: CoreDataTestCase {
    private var blog: Blog!
    private var repository: PostRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        blog = BlogBuilder(mainContext)
            .with(dotComID: 80511)
            .withAnAccount()
            .build()
        try mainContext.save()

        repository = PostRepository(coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    // MARK: - New Draft

    /// Scenario: user creates a new post and saves it as a draft.
    func testSaveNewDraft() async throws {
        // GIVEN a draft post (never synced)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "Hello"
            $0.content = "content-1"
            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends only the required parameters
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "content" : "content-1",
              "date" : "2024-03-07T23:00:40+0000",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "status" : "draft",
              "title" : "Hello",
              "type" : "post"
            }
            """)
            return try HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        // WHEN
        try await repository.save(post)

        // THEN the post was created
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .draft)
    }

    /// Scenario: user creates a new post, modifies every single possible
    /// parameter, and saves it as a draft.
    func testSaveNewPublishedPostSendingAllParameters() async throws {
        // GIVEN a draft post (never synced)
        let post = makePost {
            $0.status = .draft
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.authorID = 29043
            $0.postTitle = "Hello"
            $0.content = "content-a"
            $0.password = "1234"
            $0.mt_excerpt = "excerpt-a"
            $0.wp_slug = "slug-a"

            let media = Media(context: mainContext)
            media.blog = $0.blog
            media.mediaID = 92
            $0.featuredImage = media

            $0.postFormat = "format-a"
            $0.tags = "tag-1, tag-2 "

            let category = PostCategory(context: mainContext)
            category.categoryID = 53
            category.blog = $0.blog
            category.categoryName = "test-category"
            $0.addCategories([category])

            $0.isStickyPost = true

            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends all the parameters
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "categories_by_id" : [
                53
              ],
              "content" : "content-a",
              "date" : "2024-03-07T23:00:40+0000",
              "excerpt" : "excerpt-a",
              "featured_image" : 92,
              "format" : "format-a",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "password" : "1234",
              "slug" : "slug-a",
              "status" : "draft",
              "sticky" : true,
              "terms" : {
                "post_tag" : [
                  "tag-1",
                  "tag-2"
                ]
              },
              "title" : "Hello",
              "type" : "post"
            }
            """)
            return try HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        // WHEN
        try await repository.save(post)

        // THEN the post was created
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .draft)
    }

    /// Scenario: user creates a new post and publishes it immediatelly.
    func testSaveNewDraftAndPublish() async throws {
        // GIVEN a draft post (never synced)
        let creationDate = Date(timeIntervalSince1970: 1709852440)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
            $0.dateCreated = creationDate
            $0.postTitle = "Hello"
            $0.content = "content-1"
            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends the post content and amends the status
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "content" : "content-1",
              "date" : "2024-03-07T23:00:40+0000",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "status" : "publish",
              "title" : "Hello",
              "type" : "post"
            }
            """)
            var post = WordPressComPost.mock
            post.status = PostStatusPublish
            return try HTTPStubsResponse(value: post, statusCode: 201)
        }

        // WHEN publishing a post
        var parameters = RemotePostUpdateParameters()
        parameters.status = Post.Status.publish.rawValue
        try await repository.save(post, changes: parameters)

        // THEN the post is published
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .publish)
    }

    /// Scenario: user creates a new post and schedules it.
    func testSaveNewDraftAndSchedule() async throws {
        // GIVEN a draft post (never synced)
        let creationDate = Date(timeIntervalSince1970: 1709852440)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
            $0.dateCreated = creationDate
            $0.postTitle = "Hello"
            $0.content = "content-1"
            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends the post content and amends the status
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "content" : "content-1",
              "date" : "2024-03-07T23:00:40+0000",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "status" : "future",
              "title" : "Hello",
              "type" : "post"
            }
            """)
            var post = WordPressComPost.mock
            post.status = Post.Status.scheduled.rawValue
            post.date = creationDate
            return try HTTPStubsResponse(value: post, statusCode: 201)
        }

        // WHEN publishing a post
        var parameters = RemotePostUpdateParameters()
        parameters.status = Post.Status.scheduled.rawValue
        try await repository.save(post, changes: parameters)

        // THEN the post is scheduled
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .scheduled)
    }

    /// Scenario: user creates a new post and saves it as a draft, but there
    /// is no network connection.
    func testSaveNewDraftAndPublishWhenNotConnectedToInternet() async throws {
        // GIVEN a draft post (never synced)
        let creationDate = Date(timeIntervalSince1970: 1709852440)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
            $0.dateCreated = creationDate
            $0.postTitle = "Hello"
            $0.content = "content-1"
            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends the post content and amends the status
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "content" : "content-1",
              "date" : "2024-03-07T23:00:40+0000",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "status" : "publish",
              "title" : "Hello",
              "type" : "post"
            }
            """)
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }

        // WHEN publishing a post
        var parameters = RemotePostUpdateParameters()
        parameters.status = Post.Status.publish.rawValue
        do {
            try await repository.save(post, changes: parameters)
            XCTFail("Expected the save to fail")
        } catch {
            let error = try XCTUnwrap((error as NSError).underlyingErrors.first)
            let urlError = try XCTUnwrap(error as? URLError)
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        }

        // THEN the post wasn't published
        XCTAssertEqual(post.postID, -1)
        XCTAssertEqual(post.status, .draft)
    }

    // MARK: - Existing Post

    /// Scenario: user quickly publishes an existing post.
    func testSaveExistingPostAndPublish() async throws {
        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date()
            $0.dateModified = Date()
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a server configured to accept a patch
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "status" : "publish"
            }
            """)
            var post = WordPressComPost.mock
            post.status = Post.Status.publish.rawValue
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN publishing the post
        var parameters = RemotePostUpdateParameters()
        parameters.status = Post.Status.publish.rawValue
        try await repository.save(post, changes: parameters)

        // THEN the post got published
        XCTAssertEqual(post.status, .publish)
    }

    /// Scenario: user opens an editor to edit an existing draft, updates it,
    /// and taps "Save".
    func testSaveExistingPostWithLocalRevision() async throws {
        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a local revision with an updated title
        let revision = post.createRevision()
        revision.postTitle = "new-title"

        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "title" : "new-title"
            }
            """)

            var post = WordPressComPost.mock
            post.title = "new-title"
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository.save(post)

        // THEN the title got updated
        XCTAssertEqual(post.postTitle, "new-title")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user opens an editor to edit an existing drafts, updates publish
    /// date (persistent), then publishes a post but changes the publish date (memory).
    func testSaveExistingPostAndPublishWhileChangingLocalRevision() async throws {
        let dateCreated = Date(timeIntervalSince1970: 1709852440)

        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = dateCreated
            $0.dateModified = dateCreated
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a local revision with an updated title
        let revision = post.createRevision()
        revision.postTitle = "title-b"
        revision.dateCreated = dateCreated.addingTimeInterval(3)

        // GIVEN a server configured to accept a patch
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update combining the values from
            // the local revision and applying the update
            try assertRequestBody(request, expected: """
            {
              "date" : "2024-03-07T23:00:45+0000",
              "status" : "publish",
              "title" : "title-b"
            }
            """)
            var post = WordPressComPost.mock
            post.title = "title-b"
            post.status = Post.Status.publish.rawValue
            post.date = dateCreated.addingTimeInterval(5)
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN publishing the post
        var parameters = RemotePostUpdateParameters()
        parameters.status = Post.Status.publish.rawValue
        parameters.date = dateCreated.addingTimeInterval(5)
        try await repository.save(post, changes: parameters)

        // THEN the post got published
        XCTAssertEqual(post.status, .publish)
        XCTAssertEqual(post.dateCreated, dateCreated.addingTimeInterval(5))
        XCTAssertEqual(post.postTitle, "title-b")
    }

    /// Scenario: user changes all possible fields using a local revision.
    func testSaveExistingPostWithLocalRevisionChangingAllFields() async throws {
        // GIVEN a draft post (synced)
        let dateModified = Date(timeIntervalSince1970: 1709852440)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = dateModified
            $0.dateModified = dateModified
            $0.postTitle = "Hello"
            $0.content = "<!-- wp:paragraph -->\n<p>World</p>\n<!-- /wp:paragraph -->"
        }

        // GIVEN a local revision that updates all possible fields
        let revision = try {
            let revision = post.createRevision()
            revision.status = .publish
            revision.dateCreated = dateModified.addingTimeInterval(10)
            revision.authorID = 948
            revision.postTitle = "title-b"
            revision.content = "content-b"
            revision.password = "123"
            revision.mt_excerpt = "excerpt-b"
            revision.wp_slug = "slug-b"
            revision.featuredImage = {
                let media = MediaBuilder(mainContext).build()
                media.blog = post.blog
                media.mediaID = 92
                return media
            }()

            let post = try XCTUnwrap(revision as? Post)
            post.addCategories([{
                let category = PostCategory(context: self.mainContext)
                category.categoryID = 53
                category.blog = post.blog
                category.categoryName = "test-category"
                return category
            }()])
            post.isStickyPost = true

            return revision
        }()

        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN a server where the post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "author" : 948,
              "categories_by_id" : [
                53
              ],
              "content" : "content-b",
              "date" : "2024-03-07T23:00:50+0000",
              "excerpt" : "excerpt-b",
              "featured_image" : 92,
              "if_not_modified_since" : "2024-03-07T23:00:40+0000",
              "password" : "123",
              "slug" : "slug-b",
              "status" : "publish",
              "sticky" : true,
              "title" : "title-b"
            }
            """)

            var post = WordPressComPost.mock
            post.title = "title-b"
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository.save(post)

        // THEN the title got updated
        XCTAssertEqual(post.postTitle, "title-b")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user edits a post that got trashed on the backend.
    func testSaveExistingPostTrashedOnServer() async throws {
        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a local revision with an updated title
        let revision = post.createRevision()
        revision.postTitle = "title-b"

        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN a server where the post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "title" : "title-b"
            }
            """)

            var post = WordPressComPost.mock
            post.status = Post.Status.trash.rawValue
            post.title = "title-b"
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository.save(post)

        // THEN post got updated and the status now reflects the status on backend
        XCTAssertEqual(post.status, .trash)
        XCTAssertEqual(post.postTitle, "title-b")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user edits an existing post from Post Settings.
    func testSaveExistingPostUpdateWithoutCreatingRevision() async throws {
        // GIVEN a published post (synced)
        let post = makePost {
            $0.status = .publish
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "title-a"
            $0.content = "content-a"
        }

        // GIVEN
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "sticky" : true
            }
            """)

            var post = WordPressComPost.mock
            post.sticky = true
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post with changes but without creating a new revision
        var changes = RemotePostUpdateParameters()
        changes.isSticky = true
        try await repository.save(post, changes: changes)

        // THEN post got updated
        XCTAssertTrue(post.isStickyPost)
    }

    // MARK: - Existing Post (404, Not Found)

    /// Scenario: saving a post that was deleted on the remote.
    func testSaveExistingPostDeletedOnRemote() async throws {
        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a local revision with an updated title
        let revision = post.createRevision()
        revision.postTitle = "title-b"

        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN a server where the post was deleted
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "title" : "title-b"
            }
            """)

            return try HTTPStubsResponse(value: [
                "error": "unknown_post",
                "message": "Unknown post"
            ], statusCode: 404)
        }

        // WHEN saving the post that was deleted on the backend
        do {
            try await repository.save(post)
            XCTFail("Expected the save to fail")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            switch error {
            case .deleted:
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }

        // THEN the post is still in the database until the user taps OK and confirms
        XCTAssertNotNil(post.managedObjectContext)
    }

    // MARK: - Existing Post (409, Conflict)

    /// Scenario: user edits post's content, but the client is behind and the
    /// server has a new content, resulting in a data conflict. The user is
    /// presented with a conflict resolution dialog and picks the remote revision.
    func testSaveConflictContentChangeClientBehindPickRemote() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440).addingTimeInterval(-30)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)

        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            let ifNotModifiedSince = try request.getIfNotModifiedSince()
            XCTAssert(ifNotModifiedSince < serverDateModified)
            return HTTPStubsResponse(jsonObject: [
                "error": "old-revision",
                "message": "There is a revision of this post that is more recent."
            ], statusCode: 409, headers: nil)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            post.content = "content-c"
            return try HTTPStubsResponse(value: post, statusCode: 200)
        }

        var latest: RemotePost!
        do {
            // WHEN
            try await repository.save(post)
            XCTFail("Expected the request to fail")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            // THEN expect a `.conlict` error
            switch error {
            case .conflict(let value):
                latest = value
            default:
                XCTFail("Unexpected error")
            }
        }

        // WHEN the user resolves a conflict by picking the server revision
        try repository.resolveConflict(for: post, pickingRemoteRevision: latest)

        // THEN the content got updated to the server's version
        XCTAssertEqual(post.content, "content-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user edits post's content, but the client is behind and the
    /// server has a new content, resulting in a data conflict. The user is
    /// presented with a conflict resolution dialog and picks the local revision
    /// and retries the save.
    func testSaveConflictContentChangeClientBehindPickLocal() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)
            .addingTimeInterval(30)

        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN server revision that's ahead and has new `title` and `content`
        let serverPost = {
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            // WHEN server also has new tilte
            post.title = "title-c"
            post.content = "content-c"
            return post
        }()

        var requestCount = 0
        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            requestCount += 1

            if requestCount == 1 {
                // THEN the first request contains an `if_not_modified_since` parameter
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b",
                  "if_not_modified_since" : "2024-03-07T23:00:40+0000"
                }
                """)
                // GIVEN the first request fails with 409 (Conflict)
                let ifNotModifiedSince = try request.getIfNotModifiedSince()
                XCTAssertTrue(ifNotModifiedSince < serverDateModified)
                return HTTPStubsResponse(jsonObject: [
                    "error": "old-revision",
                    "message": "There is a revision of this post that is more recent."
                ], statusCode: 409, headers: nil)
            }
            if requestCount == 2 {
                // THEN the second request contains only the delta
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b"
                }
                """)
                var serverPost = serverPost
                serverPost.content = "content-b"
                return try HTTPStubsResponse(value: serverPost, statusCode: 200)
            }

            throw URLError(.unknown)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            try HTTPStubsResponse(value: serverPost, statusCode: 200)
        }

        do {
            // WHEN
            try await repository.save(post)
            XCTFail("Expected the request to fail")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            // THEN expect a `.conlict` error
            switch error {
            case .conflict:
                break
            default:
                XCTFail("Unexpected error")
            }
        }

        // WHEN the user picks the local version and overwrites what's on the remote
        try await repository.save(post, overwrite: true)

        // THEN the content got updated to the version from the local revision
        XCTAssertEqual(post.content, "content-b")
        // THEN the rest of the changes are consolidated on the server and the
        // new changes made elsewhere are not overwritten thanks to the detla update
        XCTAssertEqual(post.postTitle, "title-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: user edits post's content, but the client is behind and the
    /// server has a new revision but it has the same content as the original
    /// local post, so the repository resolves the conflict automatically.
    func testSaveConflictContentChangeClientBehindNoConflict() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)
            .addingTimeInterval(30)

        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN server revision that's ahead and has a new `title` but
        // the `content` is the same as the local original post
        let serverPost = {
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            post.title = "title-c"
            post.content = "content-a"
            return post
        }()

        var requestCount = 0
        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            requestCount += 1

            if requestCount == 1 {
                // THEN the first request contains an `if_not_modified_since` parameter
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b",
                  "if_not_modified_since" : "2024-03-07T23:00:40+0000"
                }
                """)
                // GIVEN the first request fails with 409 (Conflict)
                let ifNotModifiedSince = try request.getIfNotModifiedSince()
                XCTAssertTrue(ifNotModifiedSince < serverDateModified)
                return HTTPStubsResponse(jsonObject: [
                    "error": "old-revision",
                    "message": "There is a revision of this post that is more recent."
                ], statusCode: 409, headers: nil)
            }
            if requestCount == 2 {
                // THEN the second request contains only the delta
                try assertRequestBody(request, expected: """
                {
                  "content" : "content-b"
                }
                """)
                var serverPost = serverPost
                serverPost.content = "content-b"
                return try HTTPStubsResponse(value: serverPost, statusCode: 200)
            }

            throw URLError(.unknown)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            try HTTPStubsResponse(value: serverPost, statusCode: 200)
        }

        try await repository.save(post)

        // THEN the content got updated to the version from the local revision
        XCTAssertEqual(post.content, "content-b")
        // THEN the rest of the changes are consolidated on the server and the
        // new changes made elsewhere are not overwritten thanks to the detla update
        XCTAssertEqual(post.postTitle, "title-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    /// Scenario: the use sends the updated content to the server, the content
    /// gets updated on the server, but the app never recieves a response.
    func testSaveConflictFalsePositiveNoResponseFromTheServer() async throws {
        // GIVEN a draft post (client behind, server has "content-c")
        let clientDateModified = Date(timeIntervalSince1970: 1709852440)
        let serverDateModified = Date(timeIntervalSince1970: 1709852440)
            .addingTimeInterval(30)

        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = clientDateModified
            $0.dateModified = clientDateModified
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a modified content
        let revision = post.createRevision()
        revision.content = "content-b"

        try mainContext.save()

        // GIVEN server revision that's ahead and has a new `content-b` that
        // was saved after the first "partially successfull" request
        let serverPost = {
            var post = WordPressComPost.mock
            post.modified = serverDateModified
            post.title = "title-c"
            post.content = "content-b"
            return post
        }()

        var requestCount = 0
        // GIVEN a server where the post is ahead and has a new content
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            requestCount += 1

            if requestCount == 1 {
                // THEN the first request contains an `if_not_modified_since` parameter
                try assertRequestBody(request, expected: """
                    {
                      "content" : "content-b",
                      "if_not_modified_since" : "2024-03-07T23:00:40+0000"
                    }
                    """)
                // GIVEN the first request fails with 409 (Conflict)
                let ifNotModifiedSince = try request.getIfNotModifiedSince()
                XCTAssertTrue(ifNotModifiedSince < serverDateModified)
                return HTTPStubsResponse(jsonObject: [
                    "error": "old-revision",
                    "message": "There is a revision of this post that is more recent."
                ], statusCode: 409, headers: nil)
            }
            if requestCount == 2 {
                // THEN the second request contains only the delta
                try assertRequestBody(request, expected: """
                    {
                      "content" : "content-b"
                    }
                    """)
                var serverPost = serverPost
                serverPost.content = "content-b"
                return try HTTPStubsResponse(value: serverPost, statusCode: 200)
            }

            throw URLError(.unknown)
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            try HTTPStubsResponse(value: serverPost, statusCode: 200)
        }

        try await repository.save(post)

        // THEN the content got updated to the version from the local revision
        XCTAssertEqual(post.content, "content-b")
        // THEN the rest of the changes are consolidated on the server and the
        // new changes made elsewhere are not overwritten thanks to the detla update
        XCTAssertEqual(post.postTitle, "title-c")
        // THEN the local revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertNil(revision.managedObjectContext)
    }

    // MARK: - XMLRPC

    /// Scenario: saving a post that was deleted on the remote.
    func testSaveExistingPostDeletedOnRemoteWithXMLRPC() async throws {
        // GIVEN a self-hosted site
        configureSelfHostedSite()

        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "Hello"
            $0.content = "content-a"
        }

        // GIVEN a local revision with an updated title
        let revision = post.createRevision()
        revision.postTitle = "title-b"

        XCTAssertNotNil(post.revision, "Revision is missing")

        // GIVEN a server where the post
        stub(condition: { _ in true }) { request in
            // THEN the app sends a partial update
            XCTAssertEqual(request.getBodyString(), #"<?xml version="1.0"?><methodCall><methodName>wp.editPost</methodName><params><param><value><i4>0</i4></value></param><param><value><string>test</string></value></param><param><value><string>test</string></value></param><param><value><i4>974</i4></value></param><param><value><struct><member><name>post_title</name><value><string>title-b</string></value></member></struct></value></param></params></methodCall>"#)

            return HTTPStubsResponse(data: """
            <methodResponse>
              <fault>
                <value>
                  <struct>
                    <member>
                      <name>faultCode</name>
                      <value><int>404</int></value>
                    </member>
                    <member>
                      <name>faultString</name>
                      <value><string>Invalid post ID.</string></value>
                    </member>
                  </struct>
                </value>
              </fault>
            </methodResponse>
            """.data(using: .utf8)!, statusCode: 200, headers: [
                "Content-Type": "text/xml; charset=UTF-8"
            ])
        }

        // WHEN saving the post that was deleted on the backend
        do {
            try await repository.save(post)
            XCTFail("Expected the save to fail")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            switch error {
            case .deleted:
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }

        // THEN the post is still in the database until the user taps OK and confirms
        XCTAssertNotNil(post.managedObjectContext)
    }

    // MARK: - Sync (Drafts)

    /// Scenarios: the app syncs drafts post while the editor is opened.
    func testSyncExistingDraftPostWithUnsavedChangesDuringEditing() async throws {
        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "title-a"
            $0.content = "content-a"
        }

        // GIVEN a post that has changes that need to be synced (across two local revision)
        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.remoteStatus = .syncNeeded

        let revision2 = revision1.createRevision()
        revision2.postTitle = "title-c"
        revision2.remoteStatus = .syncNeeded

        // GIVEN a revision created by an editor
        let revision3 = revision2.createRevision()
        revision3.postTitle = "title-d"

        // GIVEN a server where the post was deleted
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "title" : "title-c"
            }
            """)

            var post = WordPressComPost.mock
            post.title = "title-c"
            post.sticky = true
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository.sync(post)

        // THEN it uploads the latest revision and applies the revision1 to the post
        XCTAssertEqual(post.postTitle, "title-c")
        XCTAssertTrue(post.revision == revision3)

        // THEN but doesn't apply the remote changes to make sure the app could
        // still correctly track local changes (revision0 vs revision2)
        XCTAssertFalse(post.isStickyPost)

        // GIVEN
        HTTPStubs.removeAllStubs()
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "title" : "title-d"
            }
            """)

            var post = WordPressComPost.mock
            post.title = "title-d"
            post.sticky = true
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN
        revision3.remoteStatus = .syncNeeded
        try await repository.sync(post)

        // THEN it uploads the latest revision
        XCTAssertEqual(post.postTitle, "title-d")
        XCTAssertNil(post.revision)

        // THEN and can now safely apply the changes from the remote
        XCTAssertTrue(post.isStickyPost)
    }

    /// Scenarios: the app syncs drafts post while the editor is open. The changes
    /// include changes to the `content` that might lead to a conflict.
    func testSyncExistingDraftPostWithContentChangesDuringEditing() async throws {
        // GIVEN a draft post (synced)
        let dateModified = Date(timeIntervalSince1970: 1709852440)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = dateModified
            $0.dateModified = dateModified
            $0.postTitle = "title-a"
            $0.content = "content-a"
        }

        // GIVEN a post that has changes that need to be synced (across two local revision)
        let revision1 = post.createRevision()
        revision1.content = "content-b"
        revision1.remoteStatus = .syncNeeded

        let revision2 = revision1.createRevision()
        revision2.content = "content-c"

        // GIVEN a server where the post was deleted
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the app sends a partial update
            try assertRequestBody(request, expected: """
            {
              "content" : "content-b",
              "if_not_modified_since" : "2024-03-07T23:00:40+0000"
            }
            """)

            var post = WordPressComPost.mock
            post.content = "content-b"
            post.modified = dateModified.addingTimeInterval(5)
            return try HTTPStubsResponse(value: post, statusCode: 202)
        }

        // WHEN saving the post
        try await repository.sync(post)

        // THEN it uploads the latest revision and applies the revision1 to the post
        XCTAssertEqual(post.content, "content-b")
        XCTAssertTrue(post.revision == revision2)

        // GIVEN the app hits 409 but it's a false positive, so we are good
        HTTPStubs.removeAllStubs()

        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            // THEN the first request contains an updated `if_not_modified_since` parameter
            try assertRequestBody(request, expected: """
            {
              "content" : "content-c",
              "if_not_modified_since" : "2024-03-07T23:00:45+0000"
            }
            """)

            var post = WordPressComPost.mock
            post.content = "content-c"
            post.modified = dateModified.addingTimeInterval(10)
            return try HTTPStubsResponse(value: post, statusCode: 200)
        }

        // WHEN syncing remaining changes
        revision2.remoteStatus = .syncNeeded
        try await repository.sync(post)

        // THEN it uploads the latest revision and ignores 409 because it's
        // false positive – the app made changes based on the latest content
        XCTAssertEqual(post.content, "content-c")
        XCTAssertEqual(post.dateModified, dateModified.addingTimeInterval(10))
        XCTAssertNil(post.revision)
    }

    /// Scenario: created and saved a new draft.
    func testSyncNewDraftPost() async throws {
        // GIVEN a draft post (new)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        let revision = post.createRevision()
        revision.postTitle = "title-a"
        revision.content = "content-a"
        revision.remoteStatus = .syncNeeded

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends only the required parameters
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "content" : "content-a",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "status" : "draft",
              "title" : "title-a",
              "type" : "post"
            }
            """)
            return try HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 201)
        }

        // WHEN
        try await repository.sync(post)

        // THEN the post was created
        XCTAssertEqual(post.postID, 974)
        XCTAssertEqual(post.status, .draft)
    }

    /// Scenario: made an offline change and then reverted it.
    func testSyncRevertedChangesAreSkipped() async throws {
        // GIVEN a draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.dateCreated = Date(timeIntervalSince1970: 1709852440)
            $0.dateModified = Date(timeIntervalSince1970: 1709852440)
            $0.postTitle = "title-a"
            $0.content = "content-a"
        }

        // GIVEN a change that was reverted in a more recent revision
        let revision1 = post.createRevision()
        revision1.postTitle = "title-b"
        revision1.remoteStatus = .syncNeeded

        let revision2 = revision1.createRevision()
        revision2.postTitle = "title-a"
        revision2.remoteStatus = .syncNeeded

        // GIVEN a server with the an updated content (but not title)
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/974")) { request in
            XCTFail("No POST requests should be made")
            return HTTPStubsResponse(error: URLError(.unknown))
        }

        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            XCTFail("No GET requests should be made")
            return HTTPStubsResponse(error: URLError(.unknown))
        }

        // WHEN saving the post
        try await repository.sync(post)

        // THEN the local revisions are deleted
        XCTAssertEqual(post.postTitle, "title-a")
        XCTAssertNil(post.revision)
    }

    /// Scenario: saved a new draft and opened an editor before it syncs.
    func testSyncCreatedPostWithLocalRevision() async throws {
        // GIVEN a new draft post (not synced)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
            $0.foreignID = UUID(uuidString: "F99A6E82-0AFD-4F30-9229-929AF39DA4D9")
        }

        // GIVEN a saved revision
        let revision1 = post.createRevision()
        revision1.postTitle = "title-a"
        revision1.content = "content-a"
        revision1.remoteStatus = .syncNeeded

        // GIVEN a local revision
        let revision2 = revision1.createRevision()
        revision2.postTitle = "title-b"

        // GIVEN a server accepting the new post
        stub(condition: isPath("/rest/v1.2/sites/80511/posts/new")) { request in
            // THEN the app sends only the required parameters
            try assertRequestBody(request, expected: """
            {
              "author" : 29043,
              "content" : "content-a",
              "metadata" : [
                {
                  "key" : "wp_jp_foreign_id",
                  "operation" : "update",
                  "value" : "F99A6E82-0AFD-4F30-9229-929AF39DA4D9"
                }
              ],
              "status" : "draft",
              "title" : "title-a",
              "type" : "post"
            }
            """)
            var post = WordPressComPost.mock
            post.excerpt = "hello"
            return try HTTPStubsResponse(value: post, statusCode: 201)
        }

        // WHEN saving the post
        try await repository.sync(post)

        // THEN `postID` is saved to make sure new changes are saved using partial updates
        XCTAssertEqual(post.postID, 974)

        // THEN local revision is presereved
        XCTAssertNotNil(post.revision)
        XCTAssertEqual(post.revision?.postTitle, "title-b")

        // THEN the rest of the post content is retained because we have a local revision
        XCTAssertNil(post.mt_excerpt)
    }

    // MARK: - Trash/Delete

    func testTrashLocalPost() async throws {
        // GIVEN a new draft post (not synced)
        let post = makePost {
            $0.status = .draft
            $0.authorID = 29043
        }

        // WHEN
        try await repository.trash(post)

        // THEN the post is deleted
        XCTAssertNil(post.managedObjectContext)
    }

    func testTrashRemotePost() async throws {
        // GIVEN a existing draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.content = "content-a"
        }

        let revision = post.createRevision()
        revision.content = "content-b"

        // GIVEN
        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            try HTTPStubsResponse(value: WordPressComPost.mock, statusCode: 200)
        }
        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974/delete")) { request in
            var mock = WordPressComPost.mock
            mock.status = BasePost.Status.trash.rawValue
            return try HTTPStubsResponse(value: mock, statusCode: 201)
        }

        // WHEN
        try await repository.trash(post)

        // THEN the post is trashed
        XCTAssertEqual(post.status, .trash)

        // THEN revision is deleted
        XCTAssertEqual(post.content, "content-a")
        XCTAssertNil(post.revision)
    }

    func testTrashRemotePostAlreadyTrashedOnRemote() async throws {
        // GIVEN a existing draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.content = "content-a"
        }

        // GIVEN post trashed on the remote (and updated)
        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            var mock = WordPressComPost.mock
            mock.status = BasePost.Status.trash.rawValue
            return try HTTPStubsResponse(value: mock, statusCode: 200)
        }
        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974/delete")) { _ in
            XCTFail("/delete must not be called")
            return HTTPStubsResponse(error: URLError(.unknown))
        }

        // WHEN
        try await repository.trash(post)

        // THEN the post is trashed
        XCTAssertEqual(post.status, .trash)
    }

    func testTrashRemotePostPermanentlyDeletedOnRemote() async throws {
        // GIVEN a existing draft post (synced)
        let post = makePost {
            $0.status = .draft
            $0.postID = 974
            $0.authorID = 29043
            $0.postTitle = "title-a"
            $0.content = "content-a"
        }

        // GIVEN post permanently deleted on the remote
        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974")) { request in
            return try HTTPStubsResponse(value: [
                "error": "unknown_post",
                "message": "Unknown post"
            ], statusCode: 404)
        }
        stub(condition: isPath("/rest/v1.1/sites/80511/posts/974/delete")) { _ in
            XCTFail("/delete must not be called")
            return HTTPStubsResponse(error: URLError(.unknown))
        }

        // WHEN
        do {
            try await repository.trash(post)
            XCTFail("Expected failure")
        } catch {
            let error = try XCTUnwrap(error as? PostRepository.PostSaveError)
            switch error {
            case .deleted(let title):
                XCTAssertEqual(title, "title-a")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - Helpers

private extension PostRepositorySaveTests {
    func makePost(_ customize: (Post) -> Void) -> Post {
        let post = PostBuilder(mainContext, blog: blog).build()
        customize(post)
        return post
    }

    func configureSelfHostedSite() {
        blog.account = nil
        blog.xmlrpc = "https://example.com/xmlrpc.php"
        blog.username = "test"
        blog.password = "test"
    }
}

private func stub(condition: @escaping (URLRequest) -> Bool, _ response: @escaping (URLRequest) throws -> HTTPStubsResponse) {
    OHHTTPStubsSwift.stub(condition: condition) { request in
        do {
            return try response(request)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return HTTPStubsResponse(error: error)
        }
    }
}

private func assertRequestBody(_ request: URLRequest, expected: String, file: StaticString = #file, line: UInt = #line) throws {
    let parameters = try request.getBodyParameters()
    let data = try JSONSerialization.data(withJSONObject: parameters, options: [.sortedKeys, .prettyPrinted])
    let string = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(string, expected, "Unexpected request parameters", file: file, line: line)
}

private extension URLRequest {
    func getBodyParameters() throws -> [String: AnyHashable] {
        guard let data = httpBodyStream?.read() else {
            throw PostRepositorySaveTestsError.requestBodyEmpty
        }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let parameters = object as? [String: AnyHashable] else {
            throw PostRepositorySaveTestsError.invalidRequestBody(data)
        }
        return parameters
    }

    func getBodyString() -> String? {
        httpBodyStream?.read().flatMap { String(bytes: $0, encoding: .utf8) }
    }

    func getIfNotModifiedSince() throws -> Date {
        let parameters = try getBodyParameters()
        guard let value = parameters["if_not_modified_since"] as? String,
              let date = rfc3339DateFormatter.date(from: value) else {
            throw PostRepositorySaveTestsError.invalidRequest
        }
        return date
    }
}

private enum PostRepositorySaveTestsError: Error {
    case requestBodyEmpty
    case invalidRequest
    case invalidRequestBody(_ data: Data)
    case unexpectedRequestBody(_ lhs: Any, _ rhs: Any)
}

extension HTTPStubsResponse {
    convenience init<T: Encodable>(value: T, statusCode: Int) throws {
        let data = try encoder.encode(value)
        self.init(data: data, statusCode: Int32(statusCode), headers: nil)
    }
}

// MARK: - Server

struct WordPressComPost: Hashable, Codable {
    var id: Int
    var siteID: Int
    var date: Date
    var modified: Date
    var author: WordPressComAuthor?
    var title: String?
    var url: String?
    var content: String?
    var excerpt: String?
    var slug: String?
    var status: String?
    var sticky: Bool?
    var password: String?
    var parent: Bool?
    var type: String?
    var featuredImage: String?
    var format: String?
    var metadata: [Metadata]?

    struct Metadata: Hashable, Codable {
        let id: String
        let key: String
        let value: String
    }

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case siteID = "site_ID" // snake case with uppercase letter!!!
        case date
        case modified
        case author
        case title
        case url = "URL"
        case content
        case excerpt
        case slug
        case status
        case sticky
        case password
        case parent
        case type
        case featuredImage = "featured_image"
        case format
        case metadata
    }

    static var mock: WordPressComPost = {
        let data = try! Bundle.test.json(named: "remote-post")
        return try! decoder.decode(WordPressComPost.self, from: data)
    }()
}

struct WordPressComAuthor: Hashable, Codable {
    var id: Int
    var login: String?
    var email: Bool?
    var name: String?
    var firstName: String?
    var lastName: String?
    var siteID: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case login
        case email
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case siteID = "site_ID"
    }
}

private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(rfc3339DateFormatter)
    return decoder
}()

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(rfc3339DateFormatter)
    return encoder
}()

private let rfc3339DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
    formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
    return formatter
}()

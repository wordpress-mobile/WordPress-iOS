import Testing
@testable import WordPressData
import WordPressKit
import WordPressKitModels

@MainActor
struct ReaderPostTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    @Test func testBlogNameForDisplay() {
        let post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.entityName(), into: mainContext) as! ReaderPost
        post.blogName = "t          r          e          f          o          l          o          g          y"
        #expect(post.blogNameForDisplay() == "t r e f o l o g y")
    }

    // MARK: - findOrCreateReaderPost

    @Test func findOrCreateCreatesNewPostWhenNoneExists() {
        var existing: ObjCBool = false
        _ = PostHelper.findOrCreateReaderPost(
            withGlobalID: "global-123",
            for: nil,
            existing: &existing,
            in: mainContext
        )

        #expect(existing.boolValue == false)
    }

    @Test func findOrCreateFindsExistingPostByGlobalID() {
        // GIVEN an existing post with a known globalID
        let existingPost = NSEntityDescription.insertNewObject(
            forEntityName: "ReaderPost",
            into: mainContext
        ) as! ReaderPost
        existingPost.globalID = "global-456"
        existingPost.sortRank = 0

        // WHEN searching for the same globalID
        var existing: ObjCBool = false
        let foundPost = PostHelper.findOrCreateReaderPost(
            withGlobalID: "global-456",
            for: nil,
            existing: &existing,
            in: mainContext
        )

        // THEN it returns the same post
        #expect(existing.boolValue == true)
        #expect(foundPost.objectID == existingPost.objectID)
    }

    @Test func findOrCreateScopesToTopic() {
        let topic = NSEntityDescription.insertNewObject(
            forEntityName: ReaderTagTopic.entityName(),
            into: mainContext
        ) as! ReaderTagTopic
        topic.path = "/tags/test"
        topic.title = "Test"
        topic.type = ReaderTagTopic.TopicType

        // GIVEN a post with a topic
        let existingPost = NSEntityDescription.insertNewObject(
            forEntityName: "ReaderPost",
            into: mainContext
        ) as! ReaderPost
        existingPost.globalID = "global-789"
        existingPost.topic = topic
        existingPost.sortRank = 0

        // WHEN searching without a topic
        var existing: ObjCBool = false
        let foundPost = PostHelper.findOrCreateReaderPost(
            withGlobalID: "global-789",
            for: nil,
            existing: &existing,
            in: mainContext
        )

        // THEN it doesn't find the existing post (different topic scope)
        #expect(existing.boolValue == false)
        #expect(foundPost.objectID != existingPost.objectID)
    }

    // MARK: - updateReaderPost

    @Test func updateReaderPostMapsProperties() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.sortRank = 42

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        // Basic
        #expect(post.postTitle == "Test Title")
        #expect(post.content?.contains("Hello World") == true)
        #expect(post.permaLink == "https://example.com/post")
        #expect(post.globalID == "global-id-1")
        #expect(post.authorDisplayName == "John Doe")
        #expect(post.blogName == "Test Blog")
        #expect(post.status == .publish)

        // Numeric
        #expect(post.postID == 42)
        #expect(post.siteID == 100)
        #expect(post.likeCount == 10)
        #expect(post.commentCount == 5)
        #expect(post.sortRank == 42)

        // Boolean
        #expect(post.isBlogAtomic == true)
        #expect(post.isWPCom == true)
        #expect(post.isJetpack == true)
        #expect(post.isSiteBlocked == false)

        try mainContext.save()
    }

    @Test func updateReaderPostPreservesSortRankForExistingSearchResult() throws {
        let topic = NSEntityDescription.insertNewObject(
            forEntityName: ReaderSearchTopic.entityName(),
            into: mainContext
        ) as! ReaderSearchTopic
        topic.path = "/search/test"
        topic.title = "Search"
        topic.type = ReaderSearchTopic.TopicType

        let post = makeReaderPost()
        post.sortRank = 99

        let remotePost = makeRemotePost()
        remotePost.sortRank = 42

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: true,
            for: topic,
            in: mainContext
        )

        // sortRank should be preserved for existing search results
        #expect(post.sortRank == 99)

        try mainContext.save()
    }

    @Test func updateReaderPostUpdatesSortRankForExistingNonSearchResult() throws {
        let topic = NSEntityDescription.insertNewObject(
            forEntityName: ReaderTagTopic.entityName(),
            into: mainContext
        ) as! ReaderTagTopic
        topic.path = "/tags/test"
        topic.title = "Test"
        topic.type = ReaderTagTopic.TopicType

        let post = makeReaderPost()
        post.sortRank = 99

        let remotePost = makeRemotePost()
        remotePost.sortRank = 42

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: true,
            for: topic,
            in: mainContext
        )

        // sortRank should be updated for non-search topics
        #expect(post.sortRank == 42)

        try mainContext.save()
    }

    @Test func updateReaderPostUsesSecondaryTagWhenPrimaryMatchesTopic() throws {
        let topic = NSEntityDescription.insertNewObject(
            forEntityName: ReaderTagTopic.entityName(),
            into: mainContext
        ) as! ReaderTagTopic
        topic.path = "/tags/swift"
        topic.title = "Swift"
        topic.type = ReaderTagTopic.TopicType
        topic.slug = "swift"

        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.primaryTag = "Swift"
        remotePost.primaryTagSlug = "swift"
        remotePost.secondaryTag = "iOS"
        remotePost.secondaryTagSlug = "ios"

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: topic,
            in: mainContext
        )

        // When primary tag matches topic slug, secondary tag is used
        #expect(post.primaryTag == "iOS")
        #expect(post.primaryTagSlug == "ios")

        try mainContext.save()
    }

    @Test func updateReaderPostUsesPrimaryTagWhenNoTopicMatch() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.primaryTag = "Swift"
        remotePost.primaryTagSlug = "swift"
        remotePost.secondaryTag = "iOS"
        remotePost.secondaryTagSlug = "ios"

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        #expect(post.primaryTag == "Swift")
        #expect(post.primaryTagSlug == "swift")

        try mainContext.save()
    }

    @Test func updateReaderPostMapsCrossPostMeta() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        let crossPostMeta = RemoteReaderCrossPostMeta()
        crossPostMeta.siteURL = "https://cross.example.com"
        crossPostMeta.postURL = "https://cross.example.com/post"
        crossPostMeta.commentURL = "https://cross.example.com/comment"
        crossPostMeta.siteID = 999
        crossPostMeta.postID = 888
        remotePost.setValue(crossPostMeta, forKey: "crossPostMeta")

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        #expect(post.crossPostMeta != nil)
        #expect(post.crossPostMeta?.siteURL == "https://cross.example.com")
        #expect(post.crossPostMeta?.postURL == "https://cross.example.com/post")
        #expect(post.crossPostMeta?.commentURL == "https://cross.example.com/comment")
        #expect(post.crossPostMeta?.siteID == 999)
        #expect(post.crossPostMeta?.postID == 888)

        try mainContext.save()
    }

    @Test func updateReaderPostClearsCrossPostMetaWhenNil() throws {
        let post = makeReaderPost()

        // First, set up cross post meta
        let meta = NSEntityDescription.insertNewObject(
            forEntityName: ReaderCrossPostMeta.classNameWithoutNamespaces(),
            into: mainContext
        ) as! ReaderCrossPostMeta
        post.crossPostMeta = meta

        // Then update without cross post meta
        let remotePost = makeRemotePost()

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        #expect(post.crossPostMeta == nil)

        try mainContext.save()
    }

    @Test func updateReaderPostAssignsTopic() throws {
        let topic = NSEntityDescription.insertNewObject(
            forEntityName: ReaderTagTopic.entityName(),
            into: mainContext
        ) as! ReaderTagTopic
        topic.path = "/tags/test"
        topic.title = "Test"
        topic.type = ReaderTagTopic.TopicType

        let post = makeReaderPost()
        let remotePost = makeRemotePost()

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: topic,
            in: mainContext
        )

        #expect(post.topic === topic)

        try mainContext.save()
    }

    @Test func updateReaderPostSetsAutoSuggestedFeaturedImage() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.autoSuggestedFeaturedImage = "https://example.com/auto-image.jpg"

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        #expect(post.pathForDisplayImage == "https://example.com/auto-image.jpg")

        try mainContext.save()
    }

    @Test func updateReaderPostStripsInlineStylesFromContent() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.content = "<p style=\"color:red\">Styled text</p>"

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        #expect(post.content?.contains("style=") == false)
        #expect(post.content?.contains("Styled text") == true)

        try mainContext.save()
    }

    @Test func updateReaderPostMapsSourceAttribution() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        let attribution = RemoteSourcePostAttribution()
        attribution.authorName = "Jane"
        attribution.authorURL = "https://example.com/jane"
        attribution.blogName = "Jane's Blog"
        attribution.blogURL = "https://janes-blog.example.com"
        attribution.avatarURL = "https://example.com/jane/avatar.png"
        attribution.blogID = 42
        attribution.postID = 100
        attribution.likeCount = 10
        attribution.commentCount = 5
        attribution.taxonomies = ["site-pick"]
        remotePost.sourceAttribution = attribution

        PostHelper.update(
            post,
            withRemotePost: remotePost,
            isExisting: false,
            for: nil,
            in: mainContext
        )

        #expect(post.sourceAttribution != nil)
        #expect(post.sourceAttribution?.authorName == "Jane")
        #expect(post.sourceAttribution?.blogName == "Jane's Blog")
        #expect(post.sourceAttribution?.attributionType == SourcePostAttribution.site)

        try mainContext.save()
    }
}

// MARK: - Helpers

private extension ReaderPostTests {
    func makeReaderPost() -> ReaderPost {
        NSEntityDescription.insertNewObject(
            forEntityName: "ReaderPost",
            into: mainContext
        ) as! ReaderPost
    }

    func makeRemotePost() -> RemoteReaderPost {
        let post = RemoteReaderPost()
        post.postID = 42
        post.postTitle = "Test Title"
        post.content = "<p>Hello World</p>"
        post.summary = "A summary"
        post.permalink = "https://example.com/post"
        post.globalID = "global-id-1"
        post.status = "publish"

        post.author = "John"
        post.authorDisplayName = "John Doe"
        post.authorEmail = "john@example.com"
        post.authorURL = "https://example.com/john"
        post.authorAvatarURL = "https://example.com/john/avatar.png"
        post.authorID = 1

        post.blogName = "Test Blog"
        post.blogURL = "https://example.com"
        post.blogDescription = "A test blog"
        post.siteIconURL = "https://example.com/icon.png"

        post.siteID = 100
        post.feedID = 200
        post.feedItemID = 300
        post.organizationID = 1

        post.likeCount = 10
        post.commentCount = 5
        post.score = 99
        post.wordCount = 250
        post.readingTime = 3
        post.sortRank = 1

        post.isBlogAtomic = true
        post.isBlogPrivate = false
        post.isFollowing = true
        post.isLiked = true
        post.isReblogged = false
        post.isWPCom = true
        post.commentsOpen = true
        post.isLikesEnabled = true
        post.isSharingEnabled = true
        post.useExcerpt = false
        post.isExternal = false
        post.isJetpack = true

        post.sortDate = Date(timeIntervalSince1970: 1000000)
        post.featuredImage = "https://example.com/featured.jpg"
        post.tags = "swift,ios"

        return post
    }
}

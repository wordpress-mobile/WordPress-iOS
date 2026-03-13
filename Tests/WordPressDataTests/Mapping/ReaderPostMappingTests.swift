import CoreData
import Testing
@testable import WordPressData
import WordPressKit
import WordPressKitModels

@MainActor
struct ReaderPostMappingTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // MARK: - findOrCreate

    @Test func findOrCreateCreatesNewPostWhenNoneExists() {
        let (_, isExisting) = ReaderPost.findOrCreate(
            globalID: "global-123",
            topic: nil,
            in: mainContext
        )

        #expect(isExisting == false)
    }

    @Test func findOrCreateFindsExistingPostByGlobalID() {
        // GIVEN an existing post with a known globalID
        let existingPost = makeReaderPost()
        existingPost.globalID = "global-456"
        existingPost.sortRank = 0

        // WHEN searching for the same globalID
        let (foundPost, isExisting) = ReaderPost.findOrCreate(
            globalID: "global-456",
            topic: nil,
            in: mainContext
        )

        // THEN it returns the same post
        #expect(isExisting == true)
        #expect(foundPost.objectID == existingPost.objectID)
    }

    @Test func findOrCreateScopesToTopic() {
        let topic = makeTopic(ReaderTagTopic.self, path: "/tags/test", title: "Test")

        // GIVEN a post with a topic
        let existingPost = makeReaderPost()
        existingPost.globalID = "global-789"
        existingPost.topic = topic
        existingPost.sortRank = 0

        // WHEN searching without a topic
        let (foundPost, isExisting) = ReaderPost.findOrCreate(
            globalID: "global-789",
            topic: nil,
            in: mainContext
        )

        // THEN it doesn't find the existing post (different topic scope)
        #expect(isExisting == false)
        #expect(foundPost.objectID != existingPost.objectID)
    }

    // MARK: - update(with:)

    @Test func updateMapsProperties() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.sortRank = 42

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

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

    @Test func updatePreservesSortRankForExistingSearchResult() throws {
        let topic = makeTopic(ReaderSearchTopic.self, path: "/search/test", title: "Search")

        let post = makeReaderPost()
        post.sortRank = 99

        let remotePost = makeRemotePost()
        remotePost.sortRank = 42

        post.update(with: remotePost, isExisting: true, topic: topic, in: mainContext)

        #expect(post.sortRank == 99)

        try mainContext.save()
    }

    @Test func updateOverwritesSortRankForExistingNonSearchResult() throws {
        let topic = makeTopic(ReaderTagTopic.self, path: "/tags/test", title: "Test")

        let post = makeReaderPost()
        post.sortRank = 99

        let remotePost = makeRemotePost()
        remotePost.sortRank = 42

        post.update(with: remotePost, isExisting: true, topic: topic, in: mainContext)

        #expect(post.sortRank == 42)

        try mainContext.save()
    }

    @Test func updateUsesSecondaryTagWhenPrimaryMatchesTopic() throws {
        let topic = makeTopic(ReaderTagTopic.self, path: "/tags/swift", title: "Swift")
        (topic as! ReaderTagTopic).slug = "swift"

        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.primaryTag = "Swift"
        remotePost.primaryTagSlug = "swift"
        remotePost.secondaryTag = "iOS"
        remotePost.secondaryTagSlug = "ios"

        post.update(with: remotePost, isExisting: false, topic: topic, in: mainContext)

        #expect(post.primaryTag == "iOS")
        #expect(post.primaryTagSlug == "ios")

        try mainContext.save()
    }

    @Test func updateUsesPrimaryTagWhenNoTopicMatch() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.primaryTag = "Swift"
        remotePost.primaryTagSlug = "swift"
        remotePost.secondaryTag = "iOS"
        remotePost.secondaryTagSlug = "ios"

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

        #expect(post.primaryTag == "Swift")
        #expect(post.primaryTagSlug == "swift")

        try mainContext.save()
    }

    @Test func updateMapsCrossPostMeta() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        let crossPostMeta = RemoteReaderCrossPostMeta()
        crossPostMeta.siteURL = "https://cross.example.com"
        crossPostMeta.postURL = "https://cross.example.com/post"
        crossPostMeta.commentURL = "https://cross.example.com/comment"
        crossPostMeta.siteID = 999
        crossPostMeta.postID = 888
        remotePost.setValue(crossPostMeta, forKey: "crossPostMeta")

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

        #expect(post.crossPostMeta != nil)
        #expect(post.crossPostMeta?.siteURL == "https://cross.example.com")
        #expect(post.crossPostMeta?.postURL == "https://cross.example.com/post")
        #expect(post.crossPostMeta?.commentURL == "https://cross.example.com/comment")
        #expect(post.crossPostMeta?.siteID == 999)
        #expect(post.crossPostMeta?.postID == 888)

        try mainContext.save()
    }

    @Test func updateClearsCrossPostMetaWhenNil() throws {
        let post = makeReaderPost()

        let meta = NSEntityDescription.insertNewObject(
            forEntityName: ReaderCrossPostMeta.classNameWithoutNamespaces(),
            into: mainContext
        ) as! ReaderCrossPostMeta
        post.crossPostMeta = meta

        let remotePost = makeRemotePost()

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

        #expect(post.crossPostMeta == nil)

        try mainContext.save()
    }

    @Test func updateAssignsTopic() throws {
        let topic = makeTopic(ReaderTagTopic.self, path: "/tags/test", title: "Test")

        let post = makeReaderPost()
        let remotePost = makeRemotePost()

        post.update(with: remotePost, isExisting: false, topic: topic, in: mainContext)

        #expect(post.topic === topic)

        try mainContext.save()
    }

    @Test func updateSetsAutoSuggestedFeaturedImage() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.autoSuggestedFeaturedImage = "https://example.com/auto-image.jpg"

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

        #expect(post.pathForDisplayImage == "https://example.com/auto-image.jpg")

        try mainContext.save()
    }

    @Test func updateStripsInlineStylesFromContent() throws {
        let post = makeReaderPost()
        let remotePost = makeRemotePost()
        remotePost.content = "<p style=\"color:red\">Styled text</p>"

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

        #expect(post.content?.contains("style=") == false)
        #expect(post.content?.contains("Styled text") == true)

        try mainContext.save()
    }

    @Test func updateMapsSourceAttribution() throws {
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

        post.update(with: remotePost, isExisting: false, topic: nil, in: mainContext)

        #expect(post.sourceAttribution != nil)
        #expect(post.sourceAttribution?.authorName == "Jane")
        #expect(post.sourceAttribution?.blogName == "Jane's Blog")
        #expect(post.sourceAttribution?.attributionType == SourcePostAttribution.site)

        try mainContext.save()
    }
}

// MARK: - Helpers

private extension ReaderPostMappingTests {
    func makeReaderPost() -> ReaderPost {
        NSEntityDescription.insertNewObject(
            forEntityName: "ReaderPost",
            into: mainContext
        ) as! ReaderPost
    }

    func makeTopic<T: ReaderAbstractTopic>(_ type: T.Type, path: String, title: String) -> ReaderAbstractTopic {
        let topic = NSEntityDescription.insertNewObject(
            forEntityName: T.entityName(),
            into: mainContext
        ) as! T
        topic.path = path
        topic.title = title
        topic.type = T.TopicType
        return topic
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

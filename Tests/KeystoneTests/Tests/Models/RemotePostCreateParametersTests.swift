import Testing
@testable import WordPress
@testable import WordPressData
import WordPressKit

@Suite("RemotePostCreateParameters Tests")
@MainActor
struct RemotePostCreateParametersTests {

    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // MARK: - Initialization Tests

    @Test(arguments: [true, false], [true, false])
    func initializationPreservesPostDiscussion(allowComments: Bool, allowPings: Bool) {
        let post = Post(context: mainContext)
        post.allowComments = allowComments
        post.allowPings = allowPings

        let parameters = RemotePostCreateParameters(post: post)

        #expect(parameters.commentStatus == (allowComments ? .open : .closed))
        #expect(parameters.pingStatus == (allowPings ? .open : .closed))
    }

    @Test(
        arguments: [
            (nil, true, nil),
            (nil, false, .closed),
            (.open, true, .open),
            (.open, false, .closed),
            (.closed, true, .open),
            (.closed, false, .closed)
        ] as [(RemotePostDiscussionState?, Bool, RemotePostDiscussionState?)]
    )
    func applyPromotesUnknownDiscussionOnlyWhenClosing(
        current: RemotePostDiscussionState?,
        isOpen: Bool,
        expected: RemotePostDiscussionState?
    ) {
        var parameters = RemotePostCreateParameters(type: "post", status: "draft")
        parameters.commentStatus = current
        parameters.pingStatus = current
        var changes = RemotePostUpdateParameters()
        changes.discussion = .init(allowComments: isOpen, allowPings: isOpen)

        parameters.apply(changes)

        #expect(parameters.commentStatus == expected)
        #expect(parameters.pingStatus == expected)
    }

    @Test func initializationUsesCachedClosedDefaults() {
        let blog = Blog(context: mainContext)
        blog.settings = BlogSettings(context: mainContext)
        blog.settings?.commentsAllowed = false
        blog.settings?.pingbackInboundEnabled = false

        let parameters = RemotePostCreateParameters(post: blog.createPost())

        #expect(parameters.commentStatus == .closed)
        #expect(parameters.pingStatus == .closed)
    }

    @Test func initializationOmitsPageDiscussion() {
        let page = Page(context: mainContext)

        let parameters = RemotePostCreateParameters(post: page)

        #expect(parameters.commentStatus == nil)
        #expect(parameters.pingStatus == nil)
    }

    @Test(arguments: [nil, "invalid"] as [String?])
    func initializationDoesNotInventUnknownDiscussion(commentsStatus: String?) {
        let post = Post(context: mainContext)
        post.commentsStatus = commentsStatus
        post.pingsStatus = nil

        let parameters = RemotePostCreateParameters(post: post)

        #expect(parameters.commentStatus == nil)
        #expect(parameters.pingStatus == nil)
    }

    @Test func titleOnlyEditPreservesDiscussionOverride() {
        let post = Post(context: mainContext)
        post.allowComments = false
        post.allowPings = true
        let original = RemotePostCreateParameters(post: post)
        post.postTitle = "Updated title"

        let changes = RemotePostCreateParameters(post: post).changes(from: original)

        #expect(changes.title == "Updated title")
        #expect(changes.discussion == nil)
    }

    @Test("Basic initialization with required parameters")
    func basicInitialization() {
        let parameters = RemotePostCreateParameters(type: "post", status: "draft")

        #expect(parameters.type == "post")
        #expect(parameters.status == "draft")
        #expect(parameters.metadata.isEmpty)
        #expect(parameters.tags.isEmpty)
        #expect(parameters.categoryIDs.isEmpty)
        #expect(parameters.isSticky == false)
    }

    @Test("Initialization from Post")
    func initializationFromPost() throws {
        let post = Post(context: mainContext)
        post.postTitle = "Test Post"
        post.content = "Test content"
        post.status = .publish
        post.postFormat = "standard"
        post.isStickyPost = true

        let parameters = RemotePostCreateParameters(post: post)

        #expect(parameters.type == "post")
        #expect(parameters.status == "publish")
        #expect(parameters.title == "Test Post")
        #expect(parameters.content == "Test content")
        #expect(parameters.format == "standard")
        #expect(parameters.isSticky == true)
    }

    @Test("Initialization from Post includes social sharing metadata from raw metadata")
    func initializationFromPostIncludesSocialSharingMetadataFromRawMetadata() throws {
        let post = Post(context: mainContext)
        var metadata = PostMetadataContainer()
        metadata.setValue("message-a", for: "_wpas_mess")
        metadata.setValue("1", for: "_wpas_skip_publicize_123")
        post.rawMetadata = try metadata.encode()

        let parameters = RemotePostCreateParameters(post: post)

        #expect(parameters.metadata.contains(RemotePostMetadataItem(id: nil, key: "_wpas_mess", value: "message-a")))
        #expect(
            parameters.metadata.contains(RemotePostMetadataItem(id: nil, key: "_wpas_skip_publicize_123", value: "1"))
        )
    }

    @Test("Direct metadata manipulation")
    func directMetadataManipulation() {
        var parameters = RemotePostCreateParameters(type: "post", status: "draft")

        // Create metadata items directly
        let metadataItems = Set([
            RemotePostMetadataItem(id: "1", key: "_jetpack_newsletter_access", value: "subscribers"),
            RemotePostMetadataItem(id: "2", key: "custom_key", value: "test_value")
        ])

        parameters.metadata = metadataItems

        #expect(!parameters.metadata.isEmpty)
        #expect(parameters.metadata.count == 2)

        // Verify metadata was properly set
        let accessLevelItem = parameters.metadata.first { $0.key == "_jetpack_newsletter_access" }
        #expect(accessLevelItem?.value == "subscribers")

        let customItem = parameters.metadata.first { $0.key == "custom_key" }
        #expect(customItem?.value == "test_value")
    }
}

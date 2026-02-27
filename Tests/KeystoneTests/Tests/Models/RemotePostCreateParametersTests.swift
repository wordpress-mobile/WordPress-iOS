import Testing
@testable import WordPressData

@Suite("RemotePostCreateParameters Tests")
struct RemotePostCreateParametersTests {

    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // MARK: - Initialization Tests

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

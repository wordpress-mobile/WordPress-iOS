
@testable import WordPress
import Aztec
import WordPressEditor
import Nimble

class AztecPostViewControllerAttachmentTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        contextManager = nil
    }

    func testMediaUploadErrorsWillShowAnErrorMessageAndOverlay() {
        // Arrange
        let media = Media(context: context)
        let post = Fixtures.createPost(context: context, with: media)
        let vc = Fixtures.createAztecPostViewController(with: post)

        let attachment = vc.findAttachment(withUploadID: media.uploadID)!
        expect(attachment.message).to(beNil())
        expect(attachment.overlayImage).to(beNil())

        // Act
        let error = NSError(domain: "domain", code: 0, userInfo: nil)
        vc.mediaObserver(media: media, state: .failed(error: error))

        // Assert
        expect(attachment.message).notTo(beNil())
        expect(attachment.overlayImage).notTo(beNil())
        expect(attachment.progress).to(beNil())
    }

    func testRestartingOfMediaUploadsWillClearErrorMessageAndOverlay() {
        // Arrange
        let media = Media(context: context)
        let post = Fixtures.createPost(context: context, with: media)
        let vc = Fixtures.createAztecPostViewController(with: post)

        let attachment = vc.findAttachment(withUploadID: media.uploadID)!

        // Trigger an error
        let error = NSError(domain: "domain", code: 0, userInfo: nil)
        vc.mediaObserver(media: media, state: .failed(error: error))

        // Act
        // Simulate the restarting of uploads
        vc.mediaObserver(media: media, state: .uploading(progress: Progress(totalUnitCount: 100)))

        // Assert
        expect(attachment.message).to(beNil())
        expect(attachment.overlayImage).to(beNil())
        expect(attachment.progress).to(equal(0))
    }

    func testUpdatePostContentAfterAMediaThumbnailUpdate() {
        // Arrange
        let media = Media(context: context)
        let post = Fixtures.createPost(context: context, with: media)
        let vc = Fixtures.createAztecPostViewController(with: post)

        // Act
        vc.mediaObserver(media: media, state: .thumbnailReady(url: URL(string: "file://path/to/image.png")!))

        // Assert
        expect(post.content).toEventually(contain("src=\"file://path/to/image.png\""))
    }

    private struct Fixtures {
        static func createPost(context: NSManagedObjectContext, with media: Media) -> Post {
            let post = Post(context: context)
            post.content = """
                <p><img src="" \(MediaAttachment.uploadKey)="\(media.uploadID)"></p>
            """
            return post
        }

        static func createAztecPostViewController(with post: Post) -> AztecPostViewController {
            let vc = AztecPostViewController(post: post, replaceEditor: { (_, _) in
                // noop
            })
            // Manually setting the post here so that the `post.didSet` will be called. Without
            // this, the attachments will not be initialized.
            vc.post = post
            return vc
        }
    }
}

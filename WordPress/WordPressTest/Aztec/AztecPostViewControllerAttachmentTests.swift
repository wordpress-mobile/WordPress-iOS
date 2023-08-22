
@testable import WordPress
import Aztec
import WordPressEditor
import Nimble

class AztecPostViewControllerAttachmentTests: CoreDataTestCase {

    func testMediaUploadErrorsWillShowAnErrorMessageAndOverlay() {
        // Arrange
        let media = Media(context: mainContext)
        let post = Fixtures.createPost(context: mainContext, with: media)
        let vc = Fixtures.createAztecPostViewController(with: post)

        let attachment = vc.findAttachment(withUploadID: media.uploadID)!
        expect(attachment.message).to(beNil())
        expect(attachment.overlayImage).to(beNil())

        // Act
        vc.mediaObserver(media: media, state: .failed(error: .testInstance()))

        // Assert
        expect(attachment.message).notTo(beNil())
        expect(attachment.overlayImage).notTo(beNil())
        expect(attachment.progress).to(beNil())
    }

    func testRestartingOfMediaUploadsWillClearErrorMessageAndOverlay() {
        // Arrange
        let media = Media(context: mainContext)
        let post = Fixtures.createPost(context: mainContext, with: media)
        let vc = Fixtures.createAztecPostViewController(with: post)

        let attachment = vc.findAttachment(withUploadID: media.uploadID)!

        // Trigger an error
        vc.mediaObserver(media: media, state: .failed(error: .testInstance()))

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
        let media = Media(context: mainContext)
        let post = Fixtures.createPost(context: mainContext, with: media)
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

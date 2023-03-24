import XCTest
@testable import WordPress
import WPMediaPicker
import Nimble

class MediaLibraryPickerDataSourceTests: CoreDataTestCase {

    fileprivate var dataSource: MediaLibraryPickerDataSource!
    fileprivate var blog: Blog!
    fileprivate var post: Post!

    override func setUp() {
        super.setUp()
        blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: mainContext) as? Blog
        blog.url = "http://wordpress.com"
        blog.xmlrpc = "http://wordpress.com"
        post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: mainContext) as? Post
        post.blog = blog
        dataSource = MediaLibraryPickerDataSource(blog: blog)
    }

    func testMediaPixelSize() {
        guard let media = newImageMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        let size = media.pixelSize()
        XCTAssertTrue(size.width == 1024, "Width should be 1024")
        XCTAssertTrue(size.height == 680, "Height should be 680")
    }

    func testVideoFetchForImage() {
        guard let image = newImageMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        let expect = self.expectation(description: "Image should fail to return a video asset.")
        // test if using a image media returns an error
        image.videoAsset(completionHandler: { (asset, error) in
            expect.fulfill()
            guard let error = error as NSError?, asset == nil else {
                XCTFail("Image should fail when asked for a video")
                return
            }
            XCTAssertTrue(error.domain == WPMediaPickerErrorDomain, "Should return a WPMediaPickerError")
            XCTAssertTrue(error.code == WPMediaPickerErrorCode.videoURLNotAvailable.rawValue, "Should return a videoURLNotAvailable")
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testVideoFetchForVideo() {
        guard let video = newVideoMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        let expect = self.expectation(description: "Video asset should be returned")
        video.videoAsset(completionHandler: { (asset, error) in
            expect.fulfill()
            guard error == nil, let asset = asset else {
                XCTFail("Image should be returned without error")
                return
            }

            XCTAssertTrue(asset.duration.value > 0, "Asset should have a duration")
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testMediaGroupUpdates() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        dataSource.setMediaTypeFilter(.image)

        // This variable tracks how many times the album cover (which is what
        // the "group" is in this use case) has changed.
        var changes = 0
        dataSource.registerGroupChangeObserverBlock {
            changes += 1
        }

        // Adding a video does not change the album cover.
        let video = MediaBuilder(mainContext).build()
        video.remoteStatus = .sync
        video.blog = self.blog
        video.mediaType = .video
        contextManager.saveContextAndWait(mainContext)
        expect(changes).toNever(beGreaterThan(0))

        // Adding a newly created image changes the album cover.
        let newImage = MediaBuilder(mainContext).build()
        newImage.remoteStatus = .sync
        newImage.blog = self.blog
        newImage.mediaType = .image
        newImage.creationDate = Date()
        contextManager.saveContextAndWait(mainContext)
        expect(changes).toEventually(equal(1))

        // Adding an old image does not change the album cover.
        let oldImage = MediaBuilder(mainContext).build()
        oldImage.remoteStatus = .sync
        oldImage.blog = self.blog
        oldImage.mediaType = .image
        oldImage.creationDate = Date().advanced(by: -60)
        contextManager.saveContextAndWait(mainContext)
        expect(changes).toNever(beGreaterThan(1))
    }

    fileprivate func newImageMedia() -> Media? {
        return newMedia(fromResource: "test-image", withExtension: "jpg")
    }

    fileprivate func newVideoMedia() -> Media? {
        return newMedia(fromResource: "test-video-device-gps", withExtension: "m4v")
    }

    fileprivate func newMedia(fromResource resource: String, withExtension ext: String) -> Media? {
        var newMedia: Media?
        guard let url = Bundle(for: type(of: self)).url(forResource: resource, withExtension: ext) else {
            XCTFail("Pre condition to create media service failed")
            return nil
        }

        let service = MediaImportService(coreDataStack: contextManager)
        let expect = self.expectation(description: "Media should be create with success")
        _ = service.createMedia(with: url as NSURL, blog: blog, post: post, thumbnailCallback: nil, completion: { (media, error) in
            expect.fulfill()
            if let _ = error {
                XCTFail("Media should be created without error")
                return
            }
            newMedia = media
        })
        self.waitForExpectations(timeout: 5, handler: nil)
        return newMedia
    }

}

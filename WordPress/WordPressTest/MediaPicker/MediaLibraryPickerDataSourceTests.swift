import XCTest
@testable import WordPress
import WPMediaPicker

class MediaLibraryPickerDataSourceTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!
    fileprivate var dataSource: MediaLibraryPickerDataSource!
    fileprivate var blog: Blog!
    fileprivate var post: Post!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: context) as? Blog
        blog.url = "http://wordpress.com"
        blog.xmlrpc = "http://wordpress.com"
        post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as? Post
        post.blog = blog
        dataSource = MediaLibraryPickerDataSource(blog: blog)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        context.rollback()
        ContextManager.overrideSharedInstance(nil)
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

        let mediaService = MediaService(managedObjectContext: context)
        let expect = self.expectation(description: "Media should be create with success")
        mediaService.createMedia(with: url as NSURL, blog: blog, post: post, progress: nil, thumbnailCallback: { (media, url) in
        }, completion: { (media, error) in
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

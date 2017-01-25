import XCTest
@testable import WordPress
import WPMediaPicker

class MediaLibraryPickerDataSourceTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!
    fileprivate var dataSource: MediaLibraryPickerDataSource!
    fileprivate var blog: Blog!
    fileprivate var post: Post!

    fileprivate func newImageMedia() -> Media? {
        var newMedia: Media?
        guard let url = Bundle(for: type(of: self)).url(forResource: "test-image", withExtension: "jpg"),
            let mediaService = MediaService(managedObjectContext: context) else {
            XCTFail("Pre condition to create media service failed")
            return nil
        }
        let expect = self.expectation(description: "Media should be create with success")
        mediaService.createMedia(url: url, forPost: post.objectID, thumbnailCallback: { (url) in
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

    fileprivate func newVideoMedia() -> Media? {
        var newMedia: Media?
        guard let url = Bundle(for: type(of: self)).url(forResource: "test-video", withExtension: "mp4"),
            let mediaService = MediaService(managedObjectContext: context) else {
                XCTFail("Pre condition to create media service failed")
                return nil
        }
        let expect = self.expectation(description: "Media should be create with success")
        mediaService.createMedia(url: url, forPost: post.objectID, thumbnailCallback: { (url) in
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

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: context) as! Blog
        blog.url = "http://wordpress.com"
        blog.xmlrpc = "http://wordpress.com"
        post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName, into: context) as! Post
        post.blog = blog
        dataSource = MediaLibraryPickerDataSource(blog: blog)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        context.rollback()
        ContextManager.overrideSharedInstance(nil)
    }

    func testPixelSize() {
        guard let media = newImageMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        let size = media.pixelSize()
        XCTAssertTrue(size.width == 1024, "Width should be 1024")
        XCTAssertTrue(size.height == 680 , "Height should be 680")
    }

    func testImage() {
        guard let media = newImageMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        var expect = self.expectation(description: "Image should be returned")
        // test if using size zero give back the full image
        media.image(with: CGSize.zero, completionHandler: { (image, error) in
            expect.fulfill()
            guard error == nil, let image = image else {
                XCTFail("Image should be returned without error")
                return
            }
            let size = image.size
            XCTAssertTrue(size.width == 1024, "Width should be 1024")
            XCTAssertTrue(size.height == 680 , "Height should be 680")
        })
        self.waitForExpectations(timeout: 5, handler: nil)

        expect = self.expectation(description: "Image should be returned")
        var requestedSize = CGSize(width: 512, height: 340)
        // test if using size zero give back the full image
        media.image(with: requestedSize, completionHandler: { (image, error) in
            expect.fulfill()
            guard error == nil, let image = image else {
                XCTFail("Image should be returned without error")
                return
            }
            let size = image.size
            XCTAssertTrue(size.width == requestedSize.width, "Width should match requested size")
            XCTAssertTrue(size.height == requestedSize.height , "Height should match requested size")
        })
        self.waitForExpectations(timeout: 5, handler: nil)

        guard let video = newVideoMedia() else {
            XCTFail("Media should be created without error")
            return
        }

        expect = self.expectation(description: "Image should be returned")
        requestedSize = CGSize(width: 213, height: 120)
        video.image(with: requestedSize, completionHandler: { (image, error) in
            expect.fulfill()
            guard error == nil, let image = image else {
                XCTFail("Image should be returned without error")
                return
            }
            let size = image.size
            XCTAssertTrue(size.width == requestedSize.width, "Width should match requested siz")
            XCTAssertTrue(size.height == requestedSize.height , "Height should match requested size")
        })
        self.waitForExpectations(timeout: 5, handler: nil)

    }

    func testVideo() {
        guard let image = newImageMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        var expect = self.expectation(description: "Image should fail to return a video asset.")
        // test if using a image media returns an error
        image.videoAsset(completionHandler: { (asset, error) in
            expect.fulfill()
            guard let error = error as? NSError, asset == nil else {
                XCTFail("Image should fail when asked for a video")
                return
            }
            XCTAssertTrue(error.domain == WPMediaPickerErrorDomain, "Should return a WPMediaPickerError")
            XCTAssertTrue(error.code == WPMediaPickerErrorCode.errorCodeVideoURLNotAvailable.rawValue, "Should return a errorCodeVideoURLNotAvailable")
        })
        self.waitForExpectations(timeout: 5, handler: nil)

        guard let video = newVideoMedia() else {
            XCTFail("Media should be created without error")
            return
        }
        expect = self.expectation(description: "Video asset should be returned")
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

}

import XCTest
@testable import WordPress
import WPMediaPicker

class MediaLibraryPickerDataSourceTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!
    fileprivate var dataSource: MediaLibraryPickerDataSource!
    fileprivate var blog: Blog!
    fileprivate var post: Post!

    fileprivate func newMediaImage() -> Media? {
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
        self.waitForExpectations(timeout: 2000, handler: nil)
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
        guard let media = newMediaImage() else {
            XCTFail("Media should be created without error")
            return
        }
        let size = media.pixelSize()
        XCTAssertTrue(size.width == 1024, "Width should be 1024")
        XCTAssertTrue(size.height == 680 , "Height should be 680")
    }

}

import XCTest
@testable import WordPress

class MediaTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!

    fileprivate func newTestMedia() -> Media {
        return NSEntityDescription.insertNewObject(forEntityName: Media.classNameWithoutNamespaces(), into: context) as! Media
    }

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
    }

    override func tearDown() {
        context.rollback()
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testThatAbsoluteURLsWork() {
        do {
            let media = newTestMedia()
            let filePath = "sample.jpeg"
            var expectedAbsoluteURL = try MediaService.localMediaDirectory()
            expectedAbsoluteURL.appendPathComponent(filePath)
            media.absoluteLocalURL = expectedAbsoluteURL.absoluteString
            guard
                let localPath = media.localURL,
                let localURL = URL(string: localPath),
                let absoluteURLPath = media.absoluteLocalURL
                else {
                    XCTFail("Error building expected absolute URL: \(expectedAbsoluteURL)")
                    return
            }
            XCTAssert(localURL.lastPathComponent == expectedAbsoluteURL.lastPathComponent, "Error: unexpected local Media URL")
            XCTAssert(absoluteURLPath == expectedAbsoluteURL.absoluteString, "Error: unexpected absolute Media URL")
        } catch {
            XCTFail("Error testing absolute URLs: \(error)")
        }
    }

    func testThatAbsoluteThumbnailURLsWork() {
        do {
            let media = newTestMedia()
            let filePath = "sample-thumbnail.jpeg"
            var expectedAbsoluteURL = try MediaService.localMediaDirectory()
            expectedAbsoluteURL.appendPathComponent(filePath)
            media.absoluteThumbnailLocalURL = expectedAbsoluteURL.absoluteString
            guard
                let localPath = media.localThumbnailURL,
                let localURL = URL(string: localPath),
                let absoluteURLPath = media.absoluteThumbnailLocalURL
                else {
                    XCTFail("Error building expected absolute thumbnail URL: \(expectedAbsoluteURL)")
                    return
            }
            XCTAssert(localURL.lastPathComponent == expectedAbsoluteURL.lastPathComponent, "Error: unexpected local thumbnail Media URL")
            XCTAssert(absoluteURLPath == expectedAbsoluteURL.absoluteString, "Error: unexpected absolute thumbnail Media URL")
        } catch {
            XCTFail("Error testing absolute thumbnail URLs: \(error)")
        }
    }
}

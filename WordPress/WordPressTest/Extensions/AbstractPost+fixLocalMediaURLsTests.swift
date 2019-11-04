import XCTest
import Nimble

@testable import WordPress

class AbstractPostFixLocalMediaURLsTests: XCTestCase {
    private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
    private let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testUpdateLocalMediaPathsInCachesDirectory() {
        let post = PostBuilder(context)
            .with(remoteStatus: .failed)
            .with(image: "test.jpeg")
            .with(snippet: "<img src=\"file:///Users/wapuu/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Library/Caches/Media/thumb-test.jpeg\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\">")
            .build()

        post.fixLocalMediaURLs()

        expect(post.content)
            .to(equal("<img src=\"\(cacheDirectory.appendingPathComponent("Media/thumb-test.jpeg").absoluteString)\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\">"))
    }

    func testUpdateLocalMediaPathsInDocumentDirectory() {
        let post = PostBuilder(context)
            .with(remoteStatus: .failed)
            .with(image: "test.jpeg")
            .with(snippet: "<img src=\"file:///Users/wapuu/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Documents/Media/test.jpeg\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\">")
            .build()

        post.fixLocalMediaURLs()

        expect(post.content)
            .to(equal("<img src=\"\(documentDirectory.appendingPathComponent("Media/test.jpeg").absoluteString)\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\">"))
    }

    func testUpdateAllLocalMediaPathsButDoesNotChangeRemotePaths() {
        let post = PostBuilder(context)
            .with(remoteStatus: .failed)
            .with(image: "test.jpeg")
            .with(snippet: "<img src=\"file:///Users/wapuu/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Library/Caches/Media/thumb-test.jpeg\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\"><p>Lorem ipsum</p><img src=\"https://wordpress.com/\">")
            .build()

        post.fixLocalMediaURLs()

        expect(post.content)
            .to(equal("<img src=\"\(cacheDirectory.appendingPathComponent("Media/thumb-test.jpeg").absoluteString)\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\"><p>Lorem ipsum</p><img src=\"https://wordpress.com/\">"))
    }

    func testUpdateMultipleLocalMediaPaths() {
        let post = PostBuilder(context)
            .with(remoteStatus: .failed)
            .with(image: "test.jpeg")
            .with(image: "another.jpeg")
            .with(image: "wordpress.jpeg")
            .with(snippet: "<img src=\"file:///Users/wapuu/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Library/Caches/Media/thumb-test.jpeg\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\"><p>Lorem ipsum</p><img src=\"file:///Users/wapuu/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Documents/Media/another.jpeg\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671875/Media/p17\"><img src=\"file:///Users/wapuu/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Library/Caches/Media/thumb-wordpress.jpeg\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722672008/Media/p18\">")
            .build()

        post.fixLocalMediaURLs()

        expect(post.content)
            .to(equal("<img src=\"\(cacheDirectory.appendingPathComponent("Media/thumb-test.jpeg").absoluteString)\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671857/Media/p16\"><p>Lorem ipsum</p><img src=\"\(documentDirectory.appendingPathComponent("Media/another.jpeg").absoluteString)\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722671875/Media/p17\"><img src=\"\(cacheDirectory.appendingPathComponent("Media/thumb-wordpress.jpeg").absoluteString)\" class=\"size-full\" data-wp_upload_id=\"x-coredata://58514E00-46E2-4896-AAA1-A80722672008/Media/p18\">"))
    }
}

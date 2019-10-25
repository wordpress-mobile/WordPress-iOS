import XCTest
import Nimble

@testable import WordPress

class BasePostTests: XCTestCase {

    private var localUser: String = {
        let splitedApplicationDirectory = FileManager.default.urls(for: .applicationDirectory, in: .allDomainsMask).first!.absoluteString.split(separator: "/")
        return String(splitedApplicationDirectory[2])
    }()

    private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
    private let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!

    override func setUp() {
        super.setUp()
        createTemporaryImages()
    }

    func testCorrectlyRefreshUUIDForCachedFeaturedImage() {
        let post = PostBuilder()
            .with(pathForDisplayImage: "file:///Users/\(localUser)/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Library/Caches/Media/thumbnail-p16-1792x1792.jpeg")
            .build()

        expect(post.featuredImageURL?.absoluteString)
            .to(equal(cacheDirectory.appendingPathComponent("Media/thumbnail-p16-1792x1792.jpeg").absoluteString))
    }

    func testCorrectlyRefreshUUIDForFeaturedImageInDocumentsFolder() {
        let post = PostBuilder()
            .with(pathForDisplayImage: "file:///Users/\(localUser)/Library/Developer/CoreSimulator/Devices/E690FA1D-AE36-4267-905D-8F6E71F4FA31/data/Containers/Data/Application/79D64D5C-6A83-4290-897E-794B7CC78B9F/Documents/Media/p16-1792x1792.jpeg")
            .build()

        expect(post.featuredImageURLForDisplay()?.absoluteString)
            .to(equal(documentDirectory.appendingPathComponent("Media/p16-1792x1792.jpeg").absoluteString))
    }

    func testDoesntChangeRemoteURLs() {
        let post = PostBuilder()
            .with(pathForDisplayImage: "https://wordpress.com/image.gif")
            .build()

        expect(post.featuredImageURL).to(equal(URL(string: "https://wordpress.com/image.gif")))
    }

    private func createTemporaryImages() {
        [
            try! MediaFileManager.cache.directoryURL().appendingPathComponent("thumbnail-p16-1792x1792.jpeg"),
            try! MediaFileManager().directoryURL().appendingPathComponent("p16-1792x1792.jpeg")
            ].forEach {
                try? "".write(to: $0, atomically: true, encoding: .utf8)
        }
    }
}

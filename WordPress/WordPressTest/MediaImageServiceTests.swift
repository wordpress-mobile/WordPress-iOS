import XCTest
@testable import WordPress

class MediaImageServiceTests: CoreDataTestCase {

    // MARK: - Target Size

    func testThatLandscapeImageIsResizedToFillTargetSize() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 3000, height: 2000),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 300, height: 200)
        )
    }

    func testThatPortraitImageIsResizedToFillTargetSize() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 2000, height: 3000),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 200, height: 300)
        )
    }

    func testThatPanoramaIsResizedToSaneSize() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 4000, height: 400),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 800, height: 80)
        )
    }

    func testThatImagesAreNotUpscaled() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 30, height: 20),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 30, height: 20)
        )
    }
}

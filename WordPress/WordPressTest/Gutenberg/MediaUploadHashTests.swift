import Foundation
@testable import WordPress

class MediaUploadHashTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMediaUploadHash() {
        let preSavedHash = -3384528372733689582
        let sampleMediaID = "x-coredata://2CE343D5-9019-44AB-9C59-E393C238A497/Media/p5565"

        XCTAssertEqual(preSavedHash, sampleMediaID.hash, "The presaved hash must be equal to the generated one. If this fails the Gutenberg extension on Media called gutenbergUploadID needs to be changed")
    }

}

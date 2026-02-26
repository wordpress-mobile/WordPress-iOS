import XCTest
import MediaEditor

@testable import WordPress

class MediaEditorOperationDescriptionTests: XCTestCase {

    func testOutputsAString() {
        let array: [MediaEditorOperation] = [.crop, .rotate]

        let description = array.description

        XCTAssertEqual(description, "crop, rotate")
    }

}

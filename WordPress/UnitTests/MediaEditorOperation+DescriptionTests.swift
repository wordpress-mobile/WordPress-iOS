import XCTest
import MediaEditor
import Nimble

@testable import WordPress

class MediaEditorOperationDescriptionTests: XCTestCase {

    func testOutputsAString() {
        let array: [MediaEditorOperation] = [.crop, .rotate]

        let description = array.description

        expect(description).to(equal("crop, rotate"))
    }

}

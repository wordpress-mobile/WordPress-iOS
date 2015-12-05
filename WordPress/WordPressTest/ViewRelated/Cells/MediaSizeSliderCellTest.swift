import XCTest
@testable import WordPress

class MediaSizeSliderCellTest: XCTestCase {

    func testRounding() {
        var model = MediaSizeSliderCell.Default.model
        model.minValue = 100
        model.maxValue = 300
        model.step = 0

        model.value = 100
        XCTAssertEqual(model.value, 100)
        model.value = 300
        XCTAssertEqual(model.value, 300)
        model.value = 150
        XCTAssertEqual(model.value, 150)

        model.step  = 60

        model.value = 80
        XCTAssertEqual(model.value, 100)
        model.value = 110
        XCTAssertEqual(model.value, 120)
        model.value = 150
        XCTAssertEqual(model.value, 180)
        model.value = 295
        XCTAssertEqual(model.value, 300)
        model.value = 301
        XCTAssertEqual(model.value, 300)
        model.value = 360
        XCTAssertEqual(model.value, 300)
    }

}

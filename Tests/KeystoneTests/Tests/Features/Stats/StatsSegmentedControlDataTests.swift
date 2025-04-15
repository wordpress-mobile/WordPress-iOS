import Nimble
import XCTest
@testable import WordPress

class StatsSegmentedControlDataTests: XCTestCase {

    func testDifferenceLabel() {
        expect(StatsSegmentedControlData.fixture(difference: -12_345, differencePercent: -1).differenceLabel)
            == "-12.3K (-1%)"
        expect(StatsSegmentedControlData.fixture(difference: -12_345, differencePercent: 0).differenceLabel)
            == "-12.3K"
        expect(StatsSegmentedControlData.fixture(difference: -12_345, differencePercent: 1).differenceLabel)
            == "-12.3K (1%)"
        expect(StatsSegmentedControlData.fixture(difference: 0, differencePercent: -1).differenceLabel)
            == "0 (-1%)"
        expect(StatsSegmentedControlData.fixture(difference: 0, differencePercent: 0).differenceLabel)
            == "0"
        expect(StatsSegmentedControlData.fixture(difference: 0, differencePercent: 1).differenceLabel)
            == "0 (1%)"
        expect(StatsSegmentedControlData.fixture(difference: 12_345, differencePercent: -1).differenceLabel)
            == "+12.3K (-1%)"
        expect(StatsSegmentedControlData.fixture(difference: 12_345, differencePercent: 0).differenceLabel)
            == "+12.3K"
        expect(StatsSegmentedControlData.fixture(difference: 12_345, differencePercent: 1).differenceLabel)
            == "+12.3K (1%)"
    }
}

extension StatsSegmentedControlData {

    static func fixture(
        segmentTitle: String = "title",
        segmentData: Int = 0,
        segmentPrevData: Int = 1,
        difference: Int = 2,
        differenceText: String = "text",
        differencePercent: Int = 3
    ) -> StatsSegmentedControlData {
        StatsSegmentedControlData(
            segmentTitle: segmentTitle,
            segmentData: segmentData,
            segmentPrevData: segmentPrevData,
            difference: difference,
            differenceText: differenceText,
            differencePercent: differencePercent
        )
    }
}

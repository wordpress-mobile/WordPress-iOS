import Testing
import UIKit
@testable import WordPress

struct DonutChartViewTests {

    @Test
    func configureWithEmptySegmentsDoesNotCrash() {
        let chartView = DonutChartView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        // When totalCount > 0 but all segment values are 0, normalizedSegments()
        // filters them all out, leaving an empty array. Previously this caused
        // a crash on `0..<segments.count - 1` (range 0..<-1).
        chartView.configure(
            title: "Test",
            totalCount: 100,
            segments: [
                DonutChartView.Segment(title: "A", value: 0, color: .blue),
                DonutChartView.Segment(title: "B", value: 0, color: .red)
            ]
        )
    }

    @Test
    func configureWithValidSegmentsDoesNotCrash() {
        let chartView = DonutChartView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        chartView.configure(
            title: "Test",
            totalCount: 100,
            segments: [
                DonutChartView.Segment(title: "A", value: 60, color: .blue),
                DonutChartView.Segment(title: "B", value: 40, color: .red)
            ]
        )
    }

    @Test
    func configureWithZeroTotalCountDoesNotCrash() {
        let chartView = DonutChartView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        chartView.configure(
            title: "Test",
            totalCount: 0,
            segments: []
        )
    }
}

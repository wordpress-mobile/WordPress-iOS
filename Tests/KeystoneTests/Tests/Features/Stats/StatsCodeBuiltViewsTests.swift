import Testing
import UIKit
import WordPressKit
import WordPressUI
@testable import WordPress

/// Guards details of the code-built Stats views that their xibs used to set implicitly.
@MainActor
struct StatsCodeBuiltViewsTests {

    /// A label with a `nil` background must not be opaque, or it draws on black.
    @Test func statsLabelsAreNotOpaque() {
        let label = UILabel.makeStatsLabel(text: "Label", textStyle: .body)

        #expect(label.isOpaque == false)
        #expect(label.backgroundColor == nil)
    }

    /// The loading shimmer only covers views without subviews. A system button laid out with
    /// Auto Layout gains a hidden title label, so the day square must stay a leaf view.
    @Test func postingActivityDayStaysALeafViewForTheShimmer() {
        let day = PostingActivityDay()
        day.configure(dayData: PostingStreakEvent(date: Date(), postCount: 0))
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        container.addSubview(day)
        day.frame = container.bounds
        container.layoutIfNeeded()

        #expect(day.dayButton.subviews.isEmpty)
        #expect(day.dayButton.frame == CGRect(x: 4, y: 4, width: 12, height: 12))

        let layersBefore = day.dayButton.layer.sublayers?.count ?? 0
        day.startGhostAnimation(style: GhostCellStyle.muriel)
        #expect((day.dayButton.layer.sublayers?.count ?? 0) == layersBefore + 1)
    }

    /// `configureViewAsDataBar` rounds the bar using its current height, so the bar must
    /// already have its 5 pt height when the row is configured.
    @Test func totalRowDataBarIsRounded() {
        let row = StatsTotalRow()
        row.configure(
            rowData: StatsTotalRowData(
                name: "Row",
                data: "1",
                dataBarPercent: 0.5,
                statSection: .insightsTagsAndCategories
            )
        )

        #expect(row.dataBar.layer.cornerRadius == 2.5)
    }
}

import Testing
@testable import JetpackStats

@Suite("PieChartData Tests")
struct PieChartDataTests {

    // MARK: - Helper Methods

    private func makeDevice(name: String, views: Int, breakdown: DeviceBreakdown = .screensize) -> TopListItem.Device {
        TopListItem.Device(
            name: name,
            breakdown: breakdown,
            metrics: SiteMetricsSet(views: views)
        )
    }

    // MARK: - Basic Functionality Tests

    @Test("Calculates total value correctly")
    func testTotalValue() {
        let items = [
            makeDevice(name: "Mobile", views: 100),
            makeDevice(name: "Desktop", views: 50),
            makeDevice(name: "Tablet", views: 25)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.totalValue == 175)
    }

    @Test("Calculates percentages correctly")
    func testPercentages() {
        let items = [
            makeDevice(name: "Mobile", views: 60),
            makeDevice(name: "Desktop", views: 40)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.count == 2)
        #expect(data.segments[0].percentage == 60.0)
        #expect(data.segments[1].percentage == 40.0)
    }

    @Test("Sorts segments by value descending")
    func testSorting() {
        let items = [
            makeDevice(name: "Tablet", views: 10),
            makeDevice(name: "Desktop", views: 50),
            makeDevice(name: "Mobile", views: 100)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments[0].name == "Mobile")
        #expect(data.segments[1].name == "Desktop")
        #expect(data.segments[2].name == "Tablet")
    }

    // MARK: - Smart Adaptive Algorithm Tests

    @Test("Shows all segments when count is 3 or less")
    func testShowAllWhenThreeOrFewer() {
        let items = [
            makeDevice(name: "Mobile", views: 100),
            makeDevice(name: "Desktop", views: 50),
            makeDevice(name: "Tablet", views: 25)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.count == 3)
        #expect(data.segments.allSatisfy { !$0.isOther })
    }

    @Test("Always shows top 3 segments")
    func testAlwaysShowsTopThree() {
        let items = [
            makeDevice(name: "Mobile", views: 100),
            makeDevice(name: "Desktop", views: 50),
            makeDevice(name: "Tablet", views: 25),
            makeDevice(name: "Chrome", views: 1), // Below 2% threshold
            makeDevice(name: "Safari", views: 1)  // Below 2% threshold
        ]

        let data = PieChartData(items: items, metric: .views)

        // Should show top 3 + "Other"
        #expect(data.segments.count == 4)
        #expect(data.segments[0].name == "Mobile")
        #expect(data.segments[1].name == "Desktop")
        #expect(data.segments[2].name == "Tablet")
        #expect(data.segments[3].isOther == true)
    }

    @Test("Respects 2% threshold for segments beyond top 3")
    func testPercentageThreshold() {
        // Total = 1000
        let items = [
            makeDevice(name: "Mobile", views: 400),    // 40%
            makeDevice(name: "Desktop", views: 300),   // 30%
            makeDevice(name: "Tablet", views: 200),    // 20%
            makeDevice(name: "Chrome", views: 50),     // 5% (above 2% threshold)
            makeDevice(name: "Safari", views: 30),     // 3% (above 2% threshold)
            makeDevice(name: "Firefox", views: 10),    // 1% (below threshold)
            makeDevice(name: "Edge", views: 10)        // 1% (below threshold)
        ]

        let data = PieChartData(items: items, metric: .views)

        // Should show: Mobile, Desktop, Tablet, Chrome, Safari + "Other"
        #expect(data.segments.count == 6)
        #expect(data.segments[0].name == "Mobile")
        #expect(data.segments[1].name == "Desktop")
        #expect(data.segments[2].name == "Tablet")
        #expect(data.segments[3].name == "Chrome")
        #expect(data.segments[4].name == "Safari")
        #expect(data.segments[5].isOther == true)
        #expect(data.segments[5].percentage == 2.0) // Firefox + Edge
    }

    @Test("Shows up to 6 individual segments plus Other")
    func testMaximumSegmentLimit() {
        // Create 10 items where first 6 are above 2% threshold
        // Total = 1000, so 2% threshold = 20
        let items = [
            makeDevice(name: "Item1", views: 200),  // 20%
            makeDevice(name: "Item2", views: 180),  // 18%
            makeDevice(name: "Item3", views: 160),  // 16%
            makeDevice(name: "Item4", views: 140),  // 14%
            makeDevice(name: "Item5", views: 120),  // 12%
            makeDevice(name: "Item6", views: 100),  // 10%
            makeDevice(name: "Item7", views: 50),   // 5%
            makeDevice(name: "Item8", views: 30),   // 3%
            makeDevice(name: "Item9", views: 10),   // 1%
            makeDevice(name: "Item10", views: 10)   // 1%
        ]

        let data = PieChartData(items: items, metric: .views)

        // Shows all items 1-6 (all above 2% threshold) + "Other" = 7 total
        // Items 1-6 are individually shown, Items 7-10 aggregated into "Other"
        #expect(data.segments.count == 7)
        #expect(data.segments[5].isOther == false)
        #expect(data.segments[5].name == "Item6")
        #expect(data.segments[6].isOther == true)
        #expect(data.segments[6].value == 100) // Items 7-10
    }

    @Test("Does not create 'Other' when all items fit within limits")
    func testNoOtherWhenNotNeeded() {
        let items = [
            makeDevice(name: "Mobile", views: 400),
            makeDevice(name: "Desktop", views: 300),
            makeDevice(name: "Tablet", views: 200),
            makeDevice(name: "Chrome", views: 100)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.count == 4)
        #expect(data.segments.allSatisfy { !$0.isOther })
    }

    // MARK: - Edge Cases

    @Test("Handles empty items array")
    func testEmptyItems() {
        let items: [TopListItem.Device] = []
        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.isEmpty)
        #expect(data.totalValue == 0)
    }

    @Test("Handles single item")
    func testSingleItem() {
        let items = [makeDevice(name: "Mobile", views: 100)]
        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.count == 1)
        #expect(data.segments[0].percentage == 100.0)
        #expect(data.segments[0].isOther == false)
    }

    @Test("Filters out items with zero values")
    func testFiltersZeroValues() {
        let items = [
            makeDevice(name: "Mobile", views: 100),
            makeDevice(name: "Desktop", views: 0),
            makeDevice(name: "Tablet", views: 50)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.count == 2)
        #expect(data.segments.contains { $0.name == "Desktop" } == false)
    }

    @Test("Handles all items below threshold except top 3")
    func testAllItemsBelowThreshold() {
        // Total = 103
        let items = [
            makeDevice(name: "Mobile", views: 50),     // ~48.5%
            makeDevice(name: "Desktop", views: 30),    // ~29.1%
            makeDevice(name: "Tablet", views: 20),     // ~19.4%
            makeDevice(name: "Chrome", views: 1),      // ~0.97% (below threshold)
            makeDevice(name: "Safari", views: 1),      // ~0.97% (below threshold)
            makeDevice(name: "Firefox", views: 1)      // ~0.97% (below threshold)
        ]

        let data = PieChartData(items: items, metric: .views)

        // Should show top 3 + "Other"
        #expect(data.segments.count == 4)
        #expect(data.segments[3].isOther == true)
        #expect(data.segments[3].value == 3)
    }

    // MARK: - Other Segment Tests

    @Test("Other segment has unique ID")
    func testOtherSegmentUniqueID() {
        let items = [
            makeDevice(name: "Mobile", views: 100),
            makeDevice(name: "Desktop", views: 50),
            makeDevice(name: "Tablet", views: 25),
            makeDevice(name: "Chrome", views: 1),
            makeDevice(name: "Safari", views: 1)
        ]

        let data = PieChartData(items: items, metric: .views)
        let otherSegment = data.segments.first { $0.isOther }

        #expect(otherSegment != nil)
        #expect(otherSegment?.id.hasPrefix("pie-chart-other-") == true)
    }

    @Test("Other segment aggregates values correctly")
    func testOtherSegmentAggregation() {
        // Total = 1000, so 2% = 20
        let items = [
            makeDevice(name: "Mobile", views: 500),     // 50%
            makeDevice(name: "Desktop", views: 300),    // 30%
            makeDevice(name: "Tablet", views: 100),     // 10%
            makeDevice(name: "Chrome", views: 50),      // 5%
            makeDevice(name: "Safari", views: 30),      // 3%
            makeDevice(name: "Firefox", views: 10),     // 1% (below threshold)
            makeDevice(name: "Edge", views: 10)         // 1% (below threshold)
        ]

        let data = PieChartData(items: items, metric: .views)
        let otherSegment = data.segments.first { $0.isOther }

        #expect(otherSegment != nil)
        #expect(otherSegment?.value == 20) // Firefox + Edge
        #expect(otherSegment?.percentage == 2.0)
    }

    // MARK: - Real-World Scenarios

    @Test("Handles typical device distribution")
    func testTypicalDeviceDistribution() {
        let items = [
            makeDevice(name: "mobile", views: 738),
            makeDevice(name: "desktop", views: 258),
            makeDevice(name: "tablet", views: 4)
        ]

        let data = PieChartData(items: items, metric: .views)

        #expect(data.segments.count == 3)
        #expect(data.totalValue == 1000)
        #expect(data.segments[0].percentage == 73.8)
        #expect(data.segments[1].percentage == 25.8)
        #expect(data.segments[2].percentage == 0.4)
    }

    @Test("Handles browser distribution with many items")
    func testBrowserDistribution() {
        let items = [
            makeDevice(name: "chrome", views: 1063),
            makeDevice(name: "safari", views: 15),
            makeDevice(name: "miui", views: 10),
            makeDevice(name: "edge", views: 9),
            makeDevice(name: "other", views: 5),
            makeDevice(name: "firefox", views: 1),
            makeDevice(name: "opera", views: 1)
        ]

        let data = PieChartData(items: items, metric: .views)

        // Chrome is ~96%, others are small
        // Should show Chrome, Safari, Miui, Edge + "Other" (firefox, opera, other)
        #expect(data.segments.count <= 6)
        #expect(data.segments[0].name == "Chrome") // displayName capitalizes it
    }
}

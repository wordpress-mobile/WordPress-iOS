import Foundation

struct StatsReferrersChartViewModel {
    let referrers: StatsTopReferrersTimeIntervalData

    func makeReferrersChartView() -> UIView {
        // The referrers chart currently shows 3 segments. If available, it will show:
        // - WordPress.com Reader
        // - Search
        // - Other
        // Unfortunately due to the results returned by the API this just has to be checked
        // based on the title of the group, so it's really only possible for English-speaking users.
        // When we can't find a WordPress.com Reader or Search Engines group, we'll just use the top
        // two groups with the highest referrers count.

        var topReferrers: [StatsReferrer] = []
        var allReferrers = referrers.referrers

        // First, find the WordPress.com and Search groups if we can
        if let wpIndex = allReferrers.firstIndex(where: { $0.title.contains(Constants.wpComReferrerGroupTitle) }) {
            topReferrers.append(allReferrers[wpIndex])
            allReferrers.remove(at: wpIndex)
        }

        if let searchIndex = allReferrers.firstIndex(where: { $0.title.contains(Constants.searchEnginesReferrerGroupTitle) }) {
            topReferrers.append(allReferrers[searchIndex])
            allReferrers.remove(at: searchIndex)
        }

        // Then add groups from the top of the list to make up our target group count
        while topReferrers.count < (Constants.referrersMaxGroupCount-1) && allReferrers.count > 0 {
            topReferrers.append(allReferrers.removeFirst())
        }

        // Create segments for each referrer
        var segments = topReferrers.enumerated().map({ index, item in
            return DonutChartView.Segment(
                title: Constants.referrersTitlesMap[item.title] ?? item.title,
                value: CGFloat(item.viewsCount),
                color: Constants.referrersSegmentColors[index]
            )
        })

        // Create a segment for all remaining referrers – "Other"
        let otherCount = allReferrers.map({ $0.viewsCount }).reduce(0, +) + referrers.otherReferrerViewsCount
        let otherSegment = DonutChartView.Segment(
            title: Constants.otherReferrerGroupTitle,
            value: CGFloat(otherCount),
            color: Constants.referrersSegmentColors.last!
        )
        segments.append(otherSegment)

        let chartView = DonutChartView()
        chartView.configure(title: Constants.chartTitle, totalCount: CGFloat(referrers.totalReferrerViewsCount), segments: segments)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.chartHeight).isActive = true
        return chartView
    }

    private enum Constants {
        // Referrers
        // These first two titles are not localized as they're used for string matching against the API response.
        static let wpComReferrerGroupTitle = "WordPress.com Reader"
        static let searchEnginesReferrerGroupTitle = "Search Engines"
        static let otherReferrerGroupTitle = NSLocalizedString("Other", comment: "Title of Stats section that shows referrer traffic from other sources.")
        static let chartTitle = NSLocalizedString("Views", comment: "Title for chart showing site views from various referrer sources.")

        static let referrersMaxGroupCount = 3
        static let referrersSegmentColors: [UIColor] = [
            .muriel(name: .blue, .shade80),
            .muriel(name: .blue, .shade50),
            .muriel(name: .blue, .shade5)
        ]

        static let referrersTitlesMap = [
            "WordPress.com Reader": "WordPress",
            "Search Engines": NSLocalizedString("Search", comment: "Title of Stats section that shows search engine referrer traffic.")
        ]

        static let chartHeight: CGFloat = 231.0
    }
}

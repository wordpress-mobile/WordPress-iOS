import SwiftUI

struct WordAdsMetric: Identifiable, Sendable, Hashable, MetricType {
    let id: String
    let localizedTitle: String
    let systemImage: String
    let primaryColor: Color
    let aggregationStrategy: AggregationStrategy
    let isHigherValueBetter: Bool

    private init(
        id: String,
        localizedTitle: String,
        systemImage: String,
        primaryColor: Color,
        aggregationStrategy: AggregationStrategy,
        isHigherValueBetter: Bool = true
    ) {
        self.id = id
        self.localizedTitle = localizedTitle
        self.systemImage = systemImage
        self.primaryColor = primaryColor
        self.aggregationStrategy = aggregationStrategy
        self.isHigherValueBetter = isHigherValueBetter
    }

    func backgroundColor(in colorScheme: ColorScheme) -> Color {
        primaryColor.opacity(colorScheme == .light ? 0.05 : 0.15)
    }

    static func == (lhs: WordAdsMetric, rhs: WordAdsMetric) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func makeValueFormatter() -> any ValueFormatterProtocol {
        WordAdsValueFormatter(metric: self)
    }

    // MARK: - Static Metrics

    static let impressions = WordAdsMetric(
        id: "impressions",
        localizedTitle: Strings.WordAdsMetrics.adsServed,
        systemImage: "eye",
        primaryColor: Constants.Colors.blue,
        aggregationStrategy: .sum
    )

    static let cpm = WordAdsMetric(
        id: "cpm",
        localizedTitle: Strings.WordAdsMetrics.averageCPM,
        systemImage: "chart.bar",
        primaryColor: Constants.Colors.celadon,
        aggregationStrategy: .average
    )

    static let revenue = WordAdsMetric(
        id: "revenue",
        localizedTitle: Strings.WordAdsMetrics.revenue,
        systemImage: "dollarsign.circle",
        primaryColor: Constants.Colors.green,
        aggregationStrategy: .sum
    )

    static let allMetrics: [WordAdsMetric] = [.impressions, .cpm, .revenue]
}

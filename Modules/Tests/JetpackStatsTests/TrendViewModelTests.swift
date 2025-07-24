import Foundation
import Testing
@testable import JetpackStats

@Suite
struct TrendViewModelTests {

    @Test("Sign for value changes", arguments: [
        (100, 50, "+"),
        (50, 100, "-"),
        (100, 100, "+")
    ])
    func testSign(current: Int, previous: Int, expectedSign: String) {
        // GIVEN
        let viewModel = TrendViewModel(currentValue: current, previousValue: previous, metric: .views)

        // WHEN
        let sign = viewModel.sign

        // THEN
        #expect(sign == expectedSign)
    }

    @Test("Sentiment for metrics where higher is better", arguments: [
        (SiteMetric.views, 100, 50, TrendSentiment.positive),
        (.views, 50, 100, .negative),
        (.views, 100, 100, .neutral),
        (.visitors, 200, 100, .positive),
        (.visitors, 100, 200, .negative)
    ])
    func testSentimentHigherIsBetter(metric: SiteMetric, current: Int, previous: Int, expectedSentiment: TrendSentiment) {
        // GIVEN
        let viewModel = TrendViewModel(currentValue: current, previousValue: previous, metric: metric)

        // WHEN
        let sentiment = viewModel.sentiment

        // THEN
        #expect(sentiment == expectedSentiment)
    }

    @Test("Sentiment for metrics where lower is better", arguments: [
        (SiteMetric.bounceRate, 30, 40, TrendSentiment.positive),
        (.bounceRate, 40, 30, .negative),
        (.bounceRate, 30, 30, .neutral)
    ])
    func testSentimentLowerIsBetter(metric: SiteMetric, current: Int, previous: Int, expectedSentiment: TrendSentiment) {
        // GIVEN
        let viewModel = TrendViewModel(currentValue: current, previousValue: previous, metric: metric)

        // WHEN
        let sentiment = viewModel.sentiment

        // THEN
        #expect(sentiment == expectedSentiment)
    }

    @Test("Percentage calculation", arguments: [
        (150, 100, 0.5),      // 50% increase
        (50, 100, 0.5),       // 50% decrease
        (200, 100, 1.0),      // 100% increase
        (0, 100, 1.0),        // 100% decrease
        (100, 100, 0.0)       // No change
    ])
    func testPercentageCalculation(current: Int, previous: Int, expected: Decimal) {
        // GIVEN
        let viewModel = TrendViewModel(currentValue: current, previousValue: previous, metric: .views)

        // WHEN
        let percentage = viewModel.percentage

        // THEN
        #expect(percentage == expected)
    }

    @Test("Percentage calculation with zero divisor", arguments: [
        (100, 0),   // Divide by zero
        (0, 0)      // Both zero
    ])
    func testPercentageCalculationWithZeroDivisor(current: Int, previous: Int) {
        // GIVEN
        let viewModel = TrendViewModel(currentValue: current, previousValue: previous, metric: .views)

        // WHEN
        let percentage = viewModel.percentage

        // THEN
        #expect(percentage == nil)
    }

    @Test("Percentage with negative values")
    func testPercentageWithNegativeValues() {
        // GIVEN/WHEN
        let viewModel = TrendViewModel(currentValue: -50, previousValue: -100, metric: .views)

        // THEN
        #expect(viewModel.percentage == 0.5)
    }

    @Test("Formatted change string", arguments: [
        (1500, 1000, SiteMetric.views, "+500"),
        (1000, 1500, .views, "-500"),
        (1000, 1000, .views, "+0"),
        (5000, 0, .views, "+5K"),
        (0, 5000, .views, "-5K")
    ])
    func testFormattedChange(current: Int, previous: Int, metric: SiteMetric, contains: String) {
        // GIVEN
        let viewModel = TrendViewModel(
            currentValue: current,
            previousValue: previous,
            metric: metric
        )

        // WHEN
        let formattedChange = viewModel.formattedChange

        // THEN
        #expect(formattedChange.contains(contains))
    }

    @Test("Formatted percentage string", arguments: [
        (150, 100, "50%"),
        (175, 100, "75%"),
        (100, 100, "0%"),
        (125, 100, "25%"),
        (100, 0, "∞")
    ])
    func testFormattedPercentage(current: Int, previous: Int, expected: String) {
        // GIVEN
        let viewModel = TrendViewModel(currentValue: current, previousValue: previous, metric: .views)

        // WHEN
        let formatted = viewModel.formattedPercentage

        // THEN
        #expect(formatted == expected)
    }

    @Test("Edge cases with extreme values")
    func testEdgeCasesWithExtremeValues() {
        // GIVEN
        let maxInt = Int.max
        let minInt = Int.min

        // WHEN
        let viewModel1 = TrendViewModel(currentValue: maxInt, previousValue: 0, metric: .views)
        let viewModel2 = TrendViewModel(currentValue: 0, previousValue: minInt, metric: .views)
        let viewModel3 = TrendViewModel(currentValue: maxInt, previousValue: maxInt, metric: .views)

        // THEN
        #expect(viewModel1.sign == "+")
        #expect(viewModel2.sign == "+")
        #expect(viewModel3.sentiment == .neutral)
        #expect(viewModel3.percentage == 0.0)
    }
}

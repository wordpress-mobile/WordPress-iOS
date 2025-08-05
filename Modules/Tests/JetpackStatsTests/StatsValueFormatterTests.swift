import Testing
@testable import JetpackStats

struct StatsValueFormatterTests {

    @Test
    func formatTimeOnSite() {
        let formatter = StatsValueFormatter(metric: .timeOnSite)

        #expect(formatter.format(value: 0) == "0s")
        #expect(formatter.format(value: 30) == "30s")
        #expect(formatter.format(value: 59) == "59s")
        #expect(formatter.format(value: 60) == "1m 0s")
        #expect(formatter.format(value: 90) == "1m 30s")
        #expect(formatter.format(value: 120) == "2m 0s")
        #expect(formatter.format(value: 3661) == "61m 1s")
    }

    @Test
    func formatTimeOnSiteCompact() {
        let formatter = StatsValueFormatter(metric: .timeOnSite)

        #expect(formatter.format(value: 0, context: .compact) == "0s")
        #expect(formatter.format(value: 30, context: .compact) == "30s")
        #expect(formatter.format(value: 59, context: .compact) == "59s")
        #expect(formatter.format(value: 60, context: .compact) == "1m")
        #expect(formatter.format(value: 90, context: .compact) == "1m")
        #expect(formatter.format(value: 120, context: .compact) == "2m")
        #expect(formatter.format(value: 3661, context: .compact) == "61m")
    }

    @Test
    func formatBounceRate() {
        let formatter = StatsValueFormatter(metric: .bounceRate)

        #expect(formatter.format(value: 0) == "0%")
        #expect(formatter.format(value: 25) == "25%")
        #expect(formatter.format(value: 50) == "50%")
        #expect(formatter.format(value: 75) == "75%")
        #expect(formatter.format(value: 100) == "100%")
    }

    @Test
    func formatBounceRateCompact() {
        let formatter = StatsValueFormatter(metric: .bounceRate)

        #expect(formatter.format(value: 0, context: .compact) == "0%")
        #expect(formatter.format(value: 25, context: .compact) == "25%")
        #expect(formatter.format(value: 50, context: .compact) == "50%")
        #expect(formatter.format(value: 75, context: .compact) == "75%")
        #expect(formatter.format(value: 100, context: .compact) == "100%")
    }

    @Test
    func formatRegularMetrics() {
        let metrics: [SiteMetric] = [.views, .visitors, .likes, .comments]

        for metric in metrics {
            let formatter = StatsValueFormatter(metric: metric)

            #expect(formatter.format(value: 0) == "0")
            #expect(formatter.format(value: 123) == "123")
            #expect(formatter.format(value: 1234) == "1,234")
            #expect(formatter.format(value: 9999) == "9,999")
            #expect(formatter.format(value: 10000) == "10K")
            #expect(formatter.format(value: 15789) == "16K")
            #expect(formatter.format(value: 999999) == "1M")
            #expect(formatter.format(value: 1000000) == "1M")
            #expect(formatter.format(value: 1500000) == "1.5M")
        }
    }

    @Test
    func formatRegularMetricsCompact() {
        let metrics: [SiteMetric] = [.views, .visitors, .likes, .comments]

        for metric in metrics {
            let formatter = StatsValueFormatter(metric: metric)

            #expect(formatter.format(value: 0, context: .compact) == "0")
            #expect(formatter.format(value: 123, context: .compact) == "123")
            #expect(formatter.format(value: 1234, context: .compact) == "1.2K")
            #expect(formatter.format(value: 9999, context: .compact) == "10K")
            #expect(formatter.format(value: 10000, context: .compact) == "10K")
            #expect(formatter.format(value: 15789, context: .compact) == "16K")
            #expect(formatter.format(value: 999999, context: .compact) == "1M")
            #expect(formatter.format(value: 1000000, context: .compact) == "1M")
            #expect(formatter.format(value: 1500000, context: .compact) == "1.5M")
        }
    }

    @Test
    func formatNumberStatic() {
        #expect(StatsValueFormatter.formatNumber(0) == "0")
        #expect(StatsValueFormatter.formatNumber(123) == "123")
        #expect(StatsValueFormatter.formatNumber(1234) == "1.2K")
        #expect(StatsValueFormatter.formatNumber(9999) == "10K")
        #expect(StatsValueFormatter.formatNumber(10000) == "10K")
        #expect(StatsValueFormatter.formatNumber(15789) == "16K")
        #expect(StatsValueFormatter.formatNumber(999999) == "1M")
        #expect(StatsValueFormatter.formatNumber(1000000) == "1M")
        #expect(StatsValueFormatter.formatNumber(1500000) == "1.5M")
        #expect(StatsValueFormatter.formatNumber(-1234) == "-1.2K")
        #expect(StatsValueFormatter.formatNumber(-10000) == "-10K")
    }

    @Test
    func formatNumberStaticOnlyLarge() {
        #expect(StatsValueFormatter.formatNumber(0, onlyLarge: true) == "0")
        #expect(StatsValueFormatter.formatNumber(123, onlyLarge: true) == "123")
        #expect(StatsValueFormatter.formatNumber(1234, onlyLarge: true) == "1,234")
        #expect(StatsValueFormatter.formatNumber(9999, onlyLarge: true) == "9,999")
        #expect(StatsValueFormatter.formatNumber(10000, onlyLarge: true) == "10K")
        #expect(StatsValueFormatter.formatNumber(15789, onlyLarge: true) == "16K")
        #expect(StatsValueFormatter.formatNumber(999999, onlyLarge: true) == "1M")
        #expect(StatsValueFormatter.formatNumber(1000000, onlyLarge: true) == "1M")
        #expect(StatsValueFormatter.formatNumber(1500000, onlyLarge: true) == "1.5M")
        #expect(StatsValueFormatter.formatNumber(-9999, onlyLarge: true) == "-9,999")
        #expect(StatsValueFormatter.formatNumber(-10000, onlyLarge: true) == "-10K")
    }

    @Test
    func percentageChange() {
        let formatter = StatsValueFormatter(metric: .views)

        #expect(formatter.percentageChange(current: 100, previous: 100) == 0.0)
        #expect(formatter.percentageChange(current: 150, previous: 100) == 0.5)
        #expect(formatter.percentageChange(current: 200, previous: 100) == 1.0)
        #expect(formatter.percentageChange(current: 50, previous: 100) == -0.5)
        #expect(formatter.percentageChange(current: 0, previous: 100) == -1.0)
        #expect(formatter.percentageChange(current: 100, previous: 0) == 0.0)
        #expect(formatter.percentageChange(current: 0, previous: 0) == 0.0)
    }

    @Test
    func percentageChangeEdgeCases() {
        let formatter = StatsValueFormatter(metric: .views)

        #expect(formatter.percentageChange(current: 75, previous: 50) == 0.5)
        #expect(formatter.percentageChange(current: 25, previous: 50) == -0.5)
        #expect(formatter.percentageChange(current: 110, previous: 100) == 0.1)
        #expect(formatter.percentageChange(current: 90, previous: 100) == -0.1)
        #expect(formatter.percentageChange(current: 1, previous: 10) == -0.9)
        #expect(formatter.percentageChange(current: 10, previous: 1) == 9.0)
    }
}

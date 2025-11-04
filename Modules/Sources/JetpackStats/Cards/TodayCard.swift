import SwiftUI
import Charts
import WordPressUI

struct TodayCard: View {
    @ObservedObject private var viewModel: TodayCardViewModel

    @ScaledMetric(relativeTo: .title)
    private var sparklineHeight: CGFloat = 52

    private var isChevronHidden = false

    init(viewModel: TodayCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 0) {
                    headerView
                    Spacer()
                    prominentMetricLabel
                }
                sparklineView
                    .padding(.trailing, 16)
            }
            .frame(height: sparklineHeight)

            metricsView
        }
        .padding(.vertical, Constants.step2)
        .padding(.horizontal, Constants.step3)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .onAppear {
            viewModel.onAppear()
        }
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .cardStyle()
        .animation(.spring, value: viewModel.data?.id)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.Accessibility.chartContainer)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatsCardTitleView(title: Strings.Today.title)
            Text(currentDateText)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Strings.Today.title), \(currentDateText)")
    }

    private var prominentMetricLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: SiteMetric.views.systemImage)
                .font(.caption2.weight(.medium))
                .scaleEffect(x: 0.9, y: 0.9)
            Text(SiteMetric.views.localizedTitle.uppercased())
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.secondary)
        .offset(y: 7) // Get it close to the value
        .dynamicTypeSize(...DynamicTypeSize.large)
    }

    private var currentDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    func chevronHidden(_ isHidden: Bool = true) -> TodayCard {
        var copy = self
        copy.isChevronHidden = isHidden
        return copy
    }

    // MARK: - Content Views

    @ViewBuilder
    private var metricsView: some View {
        if let data = viewModel.data {
            makeMetricsView(with: data.metrics)
        } else if viewModel.isLoading {
            makeMetricsView(with: placeholderData.metrics)
                .redacted(reason: .placeholder)
                .opacity(0.66)
                .pulsating()
        } else {
            makeMetricsView(with: SiteMetricsSet())
                .grayscale(1).opacity(0.33)
        }
    }

    private func makeMetricsView(with metrics: SiteMetricsSet) -> some View {
        HStack(alignment: .bottom, spacing: 20) {
            ForEach(viewModel.configuration.metrics) { metric in
                if metric == .views {
                    TodayCardProminentMetricView(value: metrics[metric], metric: metric)
                        .offset(y: 6.5) // Compensate for the larger line height
                } else {
                    TodayCardMetricView(metric: metric, value: metrics[metric])
                }
            }
            .layoutPriority(2)

            if !isChevronHidden {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: 8, y: -3)
                    .unredacted()
                    .layoutPriority(1)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var sparklineView: some View {
        if let data = viewModel.data {
            makeSparklineView(data)
        } else {
            let placeholder = makeSparklineView(placeholderData)
                .redacted(reason: .placeholder)
            if viewModel.isLoading {
                placeholder.pulsating().opacity(0.33)
            } else {
                placeholder.grayscale(1).opacity(0.25)
            }
        }
    }

    private func makeSparklineView(_ data: TodayCardData) -> some View {
        SparklineChart(
            dataPoints: data.hourlyViews,
            previousDataPoints: data.previousHourlyViews ?? [],
            metric: .views
        )
        .frame(maxWidth: .infinity)
        .padding(.trailing, 32)
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Placeholder Data

    private var placeholderData: TodayCardData {
        // Generate hourly data points with a realistic curve peaking mid-day
        let hourlyViews = (0..<12).map { hour in
            let normalizedHour = Double(hour)
            // Create a bell curve centered around hour 14 (2 PM)
            let peakHour = 14.0
            let spread = 4.5  // Reduced spread for sharper peak
            let amplitude = 300.0  // Increased amplitude for higher peak
            let baseline = 20.0  // Lower baseline to increase contrast

            let bellCurve = amplitude * exp(-pow(normalizedHour - peakHour, 2) / (2 * pow(spread, 2))) + baseline
            let noise = Double.random(in: -30...30)
            let value = Int(bellCurve + noise)

            return (hour: hour, value: max(15, value))
        }

        let previousHourlyViews = (0..<24).map { hour in
            let normalizedHour = Double(hour)
            // Similar curve but slightly different for comparison
            let peakHour = 12.0
            let spread = 3.0  // Reduced spread for sharper peak
            let amplitude = 280.0  // Increased amplitude for higher peak
            let baseline = 18.0  // Lower baseline to increase contrast

            let bellCurve = amplitude * exp(-pow(normalizedHour - peakHour, 2) / (2 * pow(spread, 2))) + baseline
            let noise = Double.random(in: -30...30)
            let value = Int(bellCurve + noise)

            return (hour: hour, value: max(12, value))
        }

        var metricsSet = SiteMetricsSet()
        metricsSet[.views] = 1234
        metricsSet[.visitors] = 567
        metricsSet[.likes] = 89
        metricsSet[.comments] = 12

        return TodayCardData(
            hourlyViews: hourlyViews,
            previousHourlyViews: previousHourlyViews,
            metrics: metricsSet
        )
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        Menu {
            moreMenuContent
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44)
        }
        .tint(Color.primary)
    }

    @ViewBuilder
    private var moreMenuContent: some View {
        Section {
            Link(destination: URL(string: "https://wordpress.com/support/stats/understand-your-sites-traffic/")!) {
                Label(Strings.Buttons.learnMore, systemImage: "info.circle")
            }
        }
        EditCardMenuContent(cardViewModel: viewModel)
    }
}

private struct SparklineChart: View {
    let dataPoints: [(hour: Int, value: Int)]
    let previousDataPoints: [(hour: Int, value: Int)]
    let metric: SiteMetric

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Chart {
            current
            previous
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }

    // Current day's data (colored area + line)
    private var current: some ChartContent {
        ForEach(dataPoints, id: \.hour) { hour, value in
            AreaMark(
                x: .value("Hour", hour),
                y: .value("Current", value),
                series: .value("Series", "Current")
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        metric.primaryColor.opacity(colorScheme == .light ? 0.15 : 0.25),
                        metric.primaryColor.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.linear)

            LineMark(
                x: .value("Hour", hour),
                y: .value("Current", value),
                series: .value("Series", "Current")
            )
            .foregroundStyle(metric.primaryColor)
            .lineStyle(StrokeStyle(
                lineWidth: 2.5,
                lineCap: .round,
                lineJoin: .round
            ))
            .interpolationMethod(.linear)
        }
    }

    // Previous day's data (gray dashed line)
    private var previous: some ChartContent {
        ForEach(previousDataPoints, id: \.hour) { hour, value in
            AreaMark(
                x: .value("Hour", hour),
                y: .value("Previous", value),
                series: .value("Series", "Previous")
            )
            .foregroundStyle(Color.clear)
            .interpolationMethod(.linear)

            LineMark(
                x: .value("Hour", hour),
                y: .value("Previous", value),
                series: .value("Series", "Previous")
            )
            .foregroundStyle(Color.secondary.opacity(0.5))
            .lineStyle(StrokeStyle(
                lineWidth: 1.5,
                lineCap: .round,
                lineJoin: .round,
                dash: [4, 4]
            ))
            .interpolationMethod(.linear)
        }
    }
}

private struct TodayCardProminentMetricView: View {
    let value: Int?
    let metric: SiteMetric

    private var formattedValue: String {
        guard let value else { return "–" }
        return StatsValueFormatter(metric: metric)
            .format(value: value, context: .regular)
    }

    var body: some View {
        Text(formattedValue)
            .contentTransition(.numericText())
            .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
            .foregroundColor(.primary)
            .lineLimit(1)
            .animation(.spring, value: value)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

private struct TodayCardMetricView: View {
    let metric: SiteMetric
    let value: Int?

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: metric.systemImage)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary.opacity(0.8))
            Text(formattedValue)
                .contentTransition(.numericText())
                .font(.system(.headline, design: .rounded, weight: .medium))
                .tracking(-0.33)
                .foregroundStyle(Color.primary.opacity(0.9))
        }
    }

    private var formattedValue: String {
        guard let value else { return "–" }
        return StatsValueFormatter(metric: metric).format(value: value, context: .compact)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            TodayCardPreview()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

private struct TodayCardPreview: View {
    @StateObject var viewModel = TodayCardViewModel(
        configuration: TodayCardConfiguration(metrics: [.views, .visitors, .likes, .comments]),
        dateRange: Calendar.demo.makeDateRange(for: .today),
        context: .demo
    )

    var body: some View {
        TodayCard(viewModel: viewModel)
            .cardStyle()
    }
}

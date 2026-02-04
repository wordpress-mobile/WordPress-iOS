import SwiftUI
import DesignSystem
@preconcurrency import WordPressKit

struct UTMMetricStatsView: View {
    let utmMetric: TopListItem.UTMMetric

    @State private var dateRange: StatsDateRange

    @StateObject private var viewModel: TopListViewModel

    @Environment(\.context) private var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(utmMetric: TopListItem.UTMMetric, initialDateRange: StatsDateRange? = nil, context: StatsContext) {
        self.utmMetric = utmMetric

        let range = initialDateRange ?? context.calendar.makeDateRange(for: .last30Days)
        self._dateRange = State(initialValue: range)

        let configuration = TopListCardConfiguration(
            item: .postsAndPages,
            metric: .views
        )
        self._viewModel = StateObject(wrappedValue: TopListViewModel(
            configuration: configuration,
            dateRange: range,
            service: context.service,
            tracker: context.tracker,
            items: [.postsAndPages],
            filter: .utmMetric(values: utmMetric.values)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                headerView
                    .cardStyle()

                TopListCard(
                    viewModel: viewModel,
                    itemLimit: 6,
                    reserveSpace: false,
                    showMoreInline: true,
                    showItemTypePicker: false
                )
            }
            .padding(.vertical, Constants.step1)
            .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            .frame(maxWidth: horizontalSizeClass == .regular ? Constants.maxHortizontalWidth : .infinity)
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .background(Constants.Colors.background)
        .animation(.spring, value: viewModel.data.map(ObjectIdentifier.init))
        .onChange(of: dateRange) { oldValue, newValue in
            viewModel.dateRange = newValue
        }
        .onAppear {
            context.tracker?.send(.utmMetricStatsScreenShown, properties: [
                "utm_label": utmMetric.label
            ])
        }
        .navigationTitle(Strings.UTMMetricDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if horizontalSizeClass == .regular {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    StatsDateRangeButtons(dateRange: $dateRange)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if horizontalSizeClass == .compact {
                LegacyFloatingDateControl(dateRange: $dateRange)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: Constants.step3) {
            HStack(spacing: Constants.step3) {
                // Label and metrics
                VStack(alignment: .leading, spacing: Constants.step1) {
                    Text(utmMetric.label)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    // Views for period
                    if let data = calculatePeriodViews() {
                        makeViewsView(current: data.current, previous: data.previous)
                    } else {
                        makeViewsView(current: 1000, previous: 500)
                            .redacted(reason: .placeholder)
                    }
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.step3)
    }

    private func makeViewsView(current: Int, previous: Int?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: SiteMetric.views.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                Text(SiteMetric.views.localizedTitle)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            HStack(spacing: Constants.step2) {
                Text(StatsValueFormatter.formatNumber(current, onlyLarge: true))
                    .font(Constants.Typography.smallDisplayFont)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                // Trend badge
                if let previous {
                    let trend = TrendViewModel(
                        currentValue: current,
                        previousValue: previous,
                        metric: SiteMetric.views
                    )

                    HStack(spacing: 4) {
                        Image(systemName: trend.systemImage)
                            .font(.caption2.weight(.semibold))
                        Text(trend.formattedPercentage)
                            .font(.caption.weight(.medium))
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(trend.sentiment.foregroundColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trend.sentiment.backgroundColor)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private func calculatePeriodViews() -> (current: Int, previous: Int?)? {
        guard let data = viewModel.data else { return nil }

        // Sum up views from all posts in the current period
        let currentViews = data.items.compactMap { item in
            (item as? TopListItem.Post)?.metrics.views
        }.reduce(0, +)

        // Calculate previous period views if available
        var previousViews: Int?
        if !data.previousItems.isEmpty {
            previousViews = data.previousItems.values.compactMap { item in
                (item as? TopListItem.Post)?.metrics.views
            }.reduce(0, +)
        }

        return (current: currentViews, previous: previousViews)
    }
}

#Preview {
    NavigationStack {
        UTMMetricStatsView(
            utmMetric: TopListItem.UTMMetric(
                label: "google / cpc",
                values: ["google", "cpc"],
                metrics: SiteMetricsSet(views: 5000),
                posts: [
                    TopListItem.Post(
                        title: "The Future of Technology: AI and Machine Learning",
                        postID: "1",
                        postURL: URL(string: "https://example.com/post1"),
                        date: Date(),
                        type: "post",
                        author: nil,
                        metrics: SiteMetricsSet(views: 1250)
                    ),
                    TopListItem.Post(
                        title: "Understanding Climate Change",
                        postID: "2",
                        postURL: URL(string: "https://example.com/post2"),
                        date: Date(),
                        type: "post",
                        author: nil,
                        metrics: SiteMetricsSet(views: 980)
                    )
                ]
            ),
            context: StatsContext.demo
        )
    }
    .environment(\.context, StatsContext.demo)
}

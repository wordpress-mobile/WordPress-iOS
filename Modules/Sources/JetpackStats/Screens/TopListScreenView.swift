import SwiftUI
import DesignSystem
import UniformTypeIdentifiers

struct TopListScreenView: View {
    @StateObject private var viewModel: TopListViewModel

    @Environment(\.router) var router
    @Environment(\.context) var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(
        selection: TopListViewModel.Selection,
        dateRange: StatsDateRange,
        service: any StatsServiceProtocol,
        context: StatsContext,
        initialData: TopListData? = nil,
        filter: TopListViewModel.Filter? = nil,
    ) {
        let configuration = TopListCardConfiguration(
            item: selection.item,
            metric: selection.metric
        )
        self._viewModel = StateObject(wrappedValue: TopListViewModel(
            configuration: configuration,
            dateRange: dateRange,
            service: service,
            tracker: context.tracker,
            fetchLimit: nil, // Get all items
            filter: filter,
            initialData: initialData
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step4) {
                headerView
                    .background(Color(.secondarySystemBackground).opacity(0.7))
                    .cardStyle()
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)
                    .accessibilityElement(children: .contain)
                    .padding(.horizontal, Constants.step1)

                VStack {
                    listHeaderView
                        .padding(.horizontal, Constants.step1)
                        .dynamicTypeSize(...DynamicTypeSize.xLarge)
                    listContentView
                        .grayscale(viewModel.isStale ? 1 : 0)
                        .animation(.smooth, value: viewModel.isStale)
                }
                .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.vertical, Constants.step2)
            .frame(maxWidth: horizontalSizeClass == .regular ? Constants.maxHortizontalWidthPlainLists : .infinity)
            .frame(maxWidth: .infinity)
            .animation(.spring, value: viewModel.data.map(ObjectIdentifier.init))
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.selection.item.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular {
                    StatsDateRangeButtons(dateRange: $viewModel.dateRange)
                }
                Menu {
                    if let data = viewModel.data, !data.items.isEmpty {
                        ShareLink(
                            item: CSVDataRepresentation(
                                items: data.items,
                                metric: viewModel.selection.metric,
                                fileName: generateCSVFilename()
                            ),
                            preview: SharePreview(
                                generateCSVFilename(),
                                image: Image(systemName: "doc.text")
                            )
                        ) {
                            Label(Strings.Buttons.downloadCSV, systemImage: "square.and.arrow.down")
                        }
                    } else {
                        Button(action: {}) {
                            Label(Strings.Buttons.downloadCSV, systemImage: "square.and.arrow.down")
                        }
                        .disabled(true)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel(Strings.Accessibility.moreOptions)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .safeAreaInset(edge: .bottom) {
            if horizontalSizeClass == .compact {
                LegacyFloatingDateControl(dateRange: $viewModel.dateRange)
            }
        }
    }

    @ViewBuilder
    private var headerView: some View {
        HStack(alignment: .center, spacing: Constants.step1) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selection.item.getTitle(for: viewModel.selection.metric))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(context.formatters.dateRange.string(from: viewModel.dateRange.dateInterval))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Always show the metrics view to preserve identity
            metricsOverviewView(data: viewModel.data ?? mockData)
                .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
                .pulsating(viewModel.isFirstLoad)
                .animation(.smooth, value: viewModel.isFirstLoad)
        }
        .padding(.vertical, Constants.step2)
        .padding(.horizontal, Constants.step3)
    }

    private var listHeaderView: some View {
        HStack {
            Text(viewModel.selection.item.localizedTitle)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text(viewModel.selection.metric.localizedTitle)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func metricsOverviewView(data: TopListData) -> some View {
        let formattedValue = StatsValueFormatter(metric: data.metric)
            .format(value: data.metrics.total)
        let trend = TrendViewModel(
            currentValue: data.metrics.total,
            previousValue: data.metrics.previousTotal,
            metric: data.metric
        )

        VStack(alignment: .trailing, spacing: 0) {
            Text(formattedValue)
                .contentTransition(.numericText())
                .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .animation(.spring, value: formattedValue)

            Text(trend.formattedTrend)
                .font(.system(.subheadline, design: .rounded, weight: .medium)).tracking(-0.2)
                .foregroundStyle(trend.sentiment.foregroundColor)
                .padding(.top, -4)
        }
    }

    @ViewBuilder
    private var listContentView: some View {
        if viewModel.isFirstLoad {
            itemsListView(data: mockData)
                .redacted(reason: .placeholder)
                .pulsating()
        } else if let data = viewModel.data {
            if data.items.isEmpty {
                makeEmptyStateView(message: Strings.Chart.empty)
            } else {
                itemsListView(data: data)
            }
        } else {
            makeEmptyStateView(message: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
        }
    }

    private func itemsListView(data: TopListData) -> some View {
        VStack(spacing: Constants.step0_5) {
            ForEach(data.items, id: \.id) { item in
                TopListItemView(
                    item: item,
                    previousValue: data.previousItem(for: item)?.metrics[viewModel.selection.metric],
                    metric: viewModel.selection.metric,
                    maxValue: data.metrics.maxValue,
                    dateRange: viewModel.dateRange
                )
                .frame(height: TopListItemView.defaultCellHeight)
            }
        }
    }

    private func makeEmptyStateView(message: String) -> some View {
        itemsListView(data: mockData)
            .redacted(reason: .placeholder)
            .grayscale(1)
            .opacity(0.25)
            .overlay {
                SimpleErrorView(message: message)
            }
    }

    private var mockData: TopListData {
        TopListData.mock(
            for: viewModel.selection.item,
            metric: viewModel.selection.metric,
            itemCount: 10
        )
    }

    // MARK: - CSV Export

    private func generateCSVFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let itemName = viewModel.selection.item.localizedTitle
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "and")

        let metricName = viewModel.selection.metric.localizedTitle
            .replacingOccurrences(of: " ", with: "_")

        return "\(itemName)_\(metricName)_\(dateString).csv"
    }
}

#Preview {
    NavigationStack {
        TopListScreenView(
            selection: .init(item: .postsAndPages, metric: .views),
            dateRange: Calendar.demo.makeDateRange(for: .last28Days),
            service: MockStatsService(),
            context: .demo
        )
    }
}

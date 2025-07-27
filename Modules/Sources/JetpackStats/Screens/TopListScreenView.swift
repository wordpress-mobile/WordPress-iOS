import SwiftUI
import DesignSystem

struct TopListScreenView: View {
    @StateObject private var viewModel: TopListViewModel

    @Environment(\.router) var router
    @Environment(\.context) var context
    
    init(
        selection: TopListViewModel.Selection,
        dateRange: StatsDateRange,
        service: any StatsServiceProtocol,
        initialData: TopListData? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: TopListViewModel(
            selection: selection,
            dateRange: dateRange,
            service: service,
            fetchLimit: 100, // Get more items for the full screen
            initialData: initialData
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step4) {
                headerView
                    .background(Color(.secondarySystemBackground))
                    .cardStyle()

                VStack {
                    listHeaderView
                        .padding(.horizontal, Constants.step3)
                    listContentView
                }
            }
            .padding(.vertical, Constants.step2)

            .animation(.spring, value: viewModel.data.map(ObjectIdentifier.init))
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.selection.item.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(alignment: .top, spacing: Constants.step1) {
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
        .padding(Constants.step3)
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

            Text(trend.formattedTrendShort2)
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
        LazyVStack(spacing: Constants.step1 / 2) {
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
        .padding(.horizontal, Constants.step1)
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TopListScreenView(
            selection: .init(item: .postsAndPages, metric: .views),
            dateRange: Calendar.demo.makeDateRange(for: .last28Days),
            service: MockStatsService()
        )
    }
}

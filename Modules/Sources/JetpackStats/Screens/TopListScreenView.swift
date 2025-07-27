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
        initialData: TopListChartData? = nil
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
            VStack(spacing: Constants.step3) {
                headerView
                    .cardStyle()
                listContentView
            }
            .padding(.vertical, Constants.step2)
        }
        .background(Color(.secondarySystemBackground))
        .navigationTitle(viewModel.selection.item.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: Constants.step4) {
            Text(viewModel.selection.item.getTitle(for: viewModel.selection.metric))
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            
            // Always show the metrics view to preserve identity
            metricsOverviewView(data: viewModel.matchedData ?? mockData)
                .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
                .pulsating(viewModel.isFirstLoad)
                .animation(.smooth, value: viewModel.isFirstLoad)
        }
        .padding(Constants.step4)
    }
    
    @ViewBuilder
    private func metricsOverviewView(data: TopListChartData) -> some View {
        let totalValue = data.items.reduce(0) { $0 + ($1.metrics[viewModel.selection.metric] ?? 0) }
        let previousTotalValue = data.previousItems.values.reduce(0) { $0 + ($1.metrics[viewModel.selection.metric] ?? 0) }
        
        VStack(spacing: Constants.step3) {
            // Total value section
            VStack(alignment: .leading, spacing: Constants.step1) {
                Text(Strings.Metrics.total)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: Constants.step2) {
                    Text(StatsValueFormatter.formatNumber(totalValue))
                        .font(Font.make(.recoleta, textStyle: .largeTitle, weight: .medium))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    if previousTotalValue > 0 {
                        let trend = TrendViewModel(
                            currentValue: totalValue,
                            previousValue: previousTotalValue,
                            metric: viewModel.selection.metric
                        )
                        BadgeTrendIndicator(trend: trend)
                            .scaleEffect(1.2)
                    }
                }
            }
            
            // Metadata section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constants.step1) {
                    Label {
                        Text(context.formatters.dateRange.string(from: viewModel.dateRange.dateInterval))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: Constants.step2) {
                        Label {
                            Text("\(data.items.count) \(Strings.Metrics.items)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 12)
                        
                        Label {
                            Text(viewModel.selection.metric.localizedTitle)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: viewModel.selection.metric.systemImage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    
    @ViewBuilder
    private var listContentView: some View {
        Group {
            if viewModel.isFirstLoad {
                itemsListView(data: mockData)
                    .redacted(reason: .placeholder)
                    .pulsating()
            } else if let data = viewModel.matchedData {
                if data.items.isEmpty {
                    makeEmptyStateView(message: Strings.Chart.empty)
                } else {
                    itemsListView(data: data)
                }
            } else {
                makeEmptyStateView(message: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
            }
        }
    }
    
    private func itemsListView(data: TopListChartData) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(data.items.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 0) {
                    TopListItemView(
                        item: item,
                        previousValue: data.previousItem(for: item)?.metrics[viewModel.selection.metric],
                        metric: viewModel.selection.metric,
                        maxValue: data.maxValue,
                        dateRange: viewModel.dateRange
                    )
                    .frame(height: TopListItemView.defaultCellHeight)
                    
                    if index < data.items.count - 1 {
                        Divider()
                            .padding(.leading, Constants.step3)
                    }
                }
            }
        }
        .padding(.horizontal, Constants.step3)
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
    
    private var mockData: TopListChartData {
        TopListChartData.mock(
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

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
            // Gradient background for the header section
            VStack(spacing: Constants.step3) {
                headerView
                    .cardStyle()
                    .background {
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemBackground),
                                Color(.secondarySystemBackground),
                                Color(.secondarySystemBackground),
                                Color(.systemBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 500) // Approximate height to cover header area
                        .offset(y: -100)
                        .ignoresSafeArea()
                    }

                listContentView
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
        VStack(alignment: .leading, spacing: Constants.step2) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selection.item.getTitle(for: viewModel.selection.metric))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(context.formatters.dateRange.string(from: viewModel.dateRange.dateInterval))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Always show the metrics view to preserve identity
            metricsOverviewView(data: viewModel.data ?? mockData)
                .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
                .pulsating(viewModel.isFirstLoad)
                .animation(.smooth, value: viewModel.isFirstLoad)
        }
        .padding(Constants.step3)
    }
    
    @ViewBuilder
    private func metricsOverviewView(data: TopListData) -> some View {
        let totalValue = data.metrics.total
        let previousTotalValue = data.metrics.previousTotal
        let formattedValue = StatsValueFormatter(metric: viewModel.selection.metric).format(value: totalValue)
        let trend = TrendViewModel(currentValue: totalValue, previousValue: previousTotalValue, metric: viewModel.selection.metric)

        VStack(spacing: Constants.step3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedValue)
                    .contentTransition(.numericText())
                    .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .animation(.spring, value: formattedValue)

                BadgeTrendIndicator(trend: trend)
            }

            // Metadata section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constants.step1) {
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

import SwiftUI

struct TopListCard: View {
    let dateRange: StatsDateRange
    let availableItems: [TopListItemType]

    @StateObject private var viewModel: TopListCardViewModel
    @State private var selectedItem: TopListItemType
    @State private var selectedMetric: SiteMetric = .views

    private let itemLimit = 6

    @Environment(\.context) var context

    init(
        dateRange: StatsDateRange,
        availableDataTypes: [TopListItemType] = TopListItemType.allCases,
        initialDataType: TopListItemType = .postsAndPages,
        service: any StatsServiceProtocol
    ) {
        self.dateRange = dateRange
        self.availableItems = availableDataTypes

        let selectedItem = availableDataTypes.contains(initialDataType) ? initialDataType : availableDataTypes.first ?? .postsAndPages
        self._selectedItem = State(initialValue: selectedItem)

        let viewModel = TopListCardViewModel(service: service)
        self._viewModel = StateObject(wrappedValue: viewModel)

        viewModel.setSelectedMetric(.views)
        viewModel.loadData(for: selectedItem, dateRange: self.dateRange, metric: .views)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatsCardTitleView(title: selectedItem.getTitle(for: selectedMetric))
                Spacer(minLength: 44)
            }
            VStack(spacing: 12) {
                headerView
                contentView
            }
        }
        .padding(Constants.step2)
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .grayscale(viewModel.isStale ? 1 : 0)
        .animation(.smooth, value: viewModel.isStale)
        .onChange(of: selectedItem) { newValue in
            // Reset to views when data type changes, as not all metrics are available for all types
            selectedMetric = .views
            viewModel.loadData(for: newValue, dateRange: dateRange, metric: selectedMetric)
        }
        .onChange(of: selectedMetric) { _ in
            viewModel.setSelectedMetric(selectedMetric)
            viewModel.loadData(for: selectedItem, dateRange: dateRange, metric: selectedMetric)
        }
        .onChange(of: dateRange) { _ in
            viewModel.loadData(for: selectedItem, dateRange: dateRange, metric: selectedMetric)
        }
    }

    private var headerView: some View {
        HStack {
            Menu {
                ForEach(availableItems) { dataType in
                    Button {
                        selectedItem = dataType
                    } label: {
                        Label(dataType.localizedTitle, systemImage: dataType.systemImage)
                    }
                }
                .tint(Color.primary)
            } label: {
                InlineValuePickerTitle(title: selectedItem.localizedTitle)
            }
            .fixedSize()

            Spacer()

            Menu {
                ForEach(selectedItem.availableMetrics) { metric in
                    Button {
                        selectedMetric = metric
                    } label: {
                        Label(metric.localizedTitle, systemImage: metric.systemImage)
                    }
                }
                .tint(Color.primary)
            } label: {
                InlineValuePickerTitle(title: selectedMetric.localizedTitle)
            }
            .fixedSize()
        }
    }

    private var moreMenu: some View {
        Menu {
            moreMenuContent
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
    }

    @ViewBuilder
    private var moreMenuContent: some View {
        Section {
            Button {
                // Not implemented
            } label: {
                Label(Strings.Buttons.share, systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.isFirstLoad {
                topListItemsView(data: mockData)
                    .redacted(reason: .placeholder)
            } else if let data = viewModel.matchedData {
                topListItemsView(data: data)
            } else if let error = viewModel.loadingError {
                topListItemsView(data: mockData)
                    .redacted(reason: .placeholder)
                    .grayscale(1)
                    .opacity(0.8)
                    .overlay {
                        SimpleErrorView(error: error)
                            .background(Color(.systemBackground).opacity(0.66))
                    }
            }
        }
    }

    private func topListItemsView(data: TopListChartData) -> some View {
        TopListItemsView(
            data: data,
            itemLimit: itemLimit,
            showDetails: true,
            showMoreButton: true,
            onShowMore: {
                // Not implemented
            }
        )
    }

    private var mockData: TopListChartData {
        TopListChartData.mock(for: selectedItem, metric: selectedMetric, itemCount: itemLimit)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Posts & Pages
            TopListCard(
                dateRange: Calendar.demo.makeDateRange(for: .last7Days),
                availableDataTypes: [.postsAndPages, .posts, .pages],
                initialDataType: .postsAndPages,
                service: MockStatsService()
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Referrers
            TopListCard(
                dateRange: Calendar.demo.makeDateRange(for: .last30Days),
                availableDataTypes: [.referrers],
                initialDataType: .referrers,
                service: MockStatsService()
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Locations
            TopListCard(
                dateRange: Calendar.demo.makeDateRange(for: .last30Days),
                availableDataTypes: [.locations],
                initialDataType: .locations,
                service: MockStatsService()
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Authors
            TopListCard(
                dateRange: Calendar.demo.makeDateRange(for: .last30Days),
                availableDataTypes: [.authors],
                initialDataType: .authors,
                service: MockStatsService()
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

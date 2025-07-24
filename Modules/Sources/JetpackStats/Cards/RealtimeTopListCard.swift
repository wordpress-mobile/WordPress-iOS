import SwiftUI

struct RealtimeTopListCard: View {
    let availableItems: [TopListItemType]

    @StateObject private var viewModel: RealtimeTopListCardViewModel
    @State private var selectedItem: TopListItemType

    @Environment(\.context) var context
    
    init(
        availableDataTypes: [TopListItemType] = TopListItemType.allCases,
        initialDataType: TopListItemType = .postsAndPages,
        service: any StatsServiceProtocol
    ) {
        self.availableItems = availableDataTypes
        
        let selectedItem = availableDataTypes.contains(initialDataType) ? initialDataType : availableDataTypes.first ?? .postsAndPages
        self._selectedItem = State(initialValue: selectedItem)
        
        let viewModel = RealtimeTopListCardViewModel(service: service)
        self._viewModel = StateObject(wrappedValue: viewModel)
        
        viewModel.loadData(for: selectedItem)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatsCardTitleView(title: selectedItem.getTitle(for: .views))
                    .unredacted()
                Spacer()
            }
            VStack(spacing: 12) {
                headerView
                    .unredacted()
                contentView
            }
        }
        .padding()
        .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
        .onChange(of: selectedItem) { newValue in
            viewModel.loadData(for: newValue)
        }
    }
    

    private var headerView: some View {
        HStack {
            Menu {
                ForEach(availableItems) { dataType in
                    Button {
                        // Temporarily solution while there are animation isseus with Menu on iOS 26
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                            selectedItem = dataType
                        }
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

            Text("Views")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.isFirstLoad {
                loadingView
            } else if let data = viewModel.topListData {
                topListItemsView(data: data)
            } else if let error = viewModel.loadingError {
                loadingView
                    .redacted(reason: .placeholder)
                    .opacity(0.1)
                    .overlay {
                        SimpleErrorView(error: error)
                    }
            }
        }
        .animation(.spring, value: selectedItem)
    }

    private func topListItemsView(data: TopListData) -> some View {
        let chartData = TopListChartData(
            item: selectedItem,
            metric: .views,
            items: data.items.map {
                let itemID = TopListChartData.ItemID(type: selectedItem, id: $0.id)
                return TopListChartData.Item(id: itemID, current: $0, previous: nil)
            },
            maxValue: viewModel.maxValue,
        )
        
        return TopListItemsView(
            data: chartData,
            itemLimit: 6,
            dateRange: context.calendar.makeDateRange(for: .today),
            showDetails: false
        )
    }

    private var loadingView: some View {
        topListItemsView(data: mockData)
    }
    
    private var mockData: TopListData {
        let chartData = TopListChartData.mock(
            for: selectedItem,
            metric: .views,
            itemCount: 6
        )
        return TopListData(items: chartData.items.map { $0.current })
    }
    
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Posts & Pages
            RealtimeTopListCard(
                availableDataTypes: [.postsAndPages],
                initialDataType: .postsAndPages,
                service: MockStatsService()
            )
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Referrers
            RealtimeTopListCard(
                availableDataTypes: [.referrers],
                initialDataType: .referrers,
                service: MockStatsService()
            )
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Locations
            RealtimeTopListCard(
                availableDataTypes: [.locations],
                initialDataType: .locations,
                service: MockStatsService()
            )
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

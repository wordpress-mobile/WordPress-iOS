import SwiftUI

struct TopListCard: View {
    @ObservedObject private var viewModel: TopListViewModel

    private let itemLimit: Int
    private let reserveSpace: Bool
    private let showMoreInline: Bool
    private let showItemTypePicker: Bool

    @State private var isExpanded = false

    @Environment(\.context) var context
    @Environment(\.router) var router

    init(
        viewModel: TopListViewModel,
        itemLimit: Int = 5,
        reserveSpace: Bool = true,
        showMoreInline: Bool = false,
        showItemTypePicker: Bool = true
    ) {
        self.viewModel = viewModel
        self.itemLimit = itemLimit
        self.reserveSpace = reserveSpace
        self.showMoreInline = showMoreInline
        self.showItemTypePicker = showItemTypePicker
    }

    var body: some View {
        VStack(spacing: 0) {
            cardHeaderView
                .padding(.horizontal, Constants.step3)

            if viewModel.selection.item == .locations {
                mapView
                    .padding(.vertical, Constants.step2)
                    .padding(.horizontal, Constants.step2)
            }

            if viewModel.selection.item == .devices {
                pieChartView
                    .padding(.vertical, Constants.step1)
                    .padding(.horizontal, Constants.step3)
            }

            listHeaderView
                .padding(.horizontal, Constants.step3)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)

            listContentView
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onAppear {
            viewModel.onAppear()
        }
        .padding(.vertical, Constants.step2)
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .cardStyle()
        .onTapGesture {
            if !showMoreInline {
                navigateToTopListScreen()
            }
        }
        .grayscale(viewModel.isStale ? 1 : 0)
        .opacity(viewModel.isEditing ? 0.6 : 1)
        .scaleEffect(viewModel.isEditing ? 0.95 : 1)
        .animation(.smooth, value: viewModel.isStale)
        .animation(.spring, value: viewModel.isEditing)
        .accessibilityElement(children: .contain)
        .animation(.spring, value: viewModel.data.map(ObjectIdentifier.init)) // placing is important
        .sheet(isPresented: $viewModel.isEditing) {
            NavigationStack {
                TopListCardCustomizationView(viewModel: viewModel)
                    .navigationTitle(Strings.Cards.selectDataType)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var cardHeaderView: some View {
        HStack {
            if showItemTypePicker {
                Menu {
                    itemTypePicker
                } label: {
                    StatsCardTitleView(title: viewModel.selection.item.localizedTitle, showChevron: true)
                }
            } else {
                StatsCardTitleView(title: viewModel.selection.item.localizedTitle, showChevron: false)
            }
            Spacer(minLength: 44)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.cardTitle(viewModel.title))
    }

    private var mapView: some View {
        CountriesMapView(
            data: viewModel.countriesMapData ?? .init(metric: viewModel.selection.metric, locations: []),
            primaryColor: Constants.Colors.uiColorBlue
        )
    }

    private var pieChartView: some View {
        let mockPieData = PieChartData(items: mockData.items, metric: viewModel.selection.metric)
        let isShowingMockData = viewModel.isFirstLoad || viewModel.pieChartData == nil
        let data = viewModel.pieChartData ?? mockPieData

        return PieChartView(data: data)
            .frame(height: 200)
            .allowsHitTesting(!isShowingMockData)
            .redacted(reason: isShowingMockData ? .placeholder : [])
            .opacity(isShowingMockData ? 0.2 : 1.0)
            .pulsating(isShowingMockData && viewModel.isFirstLoad)
    }

    private var listHeaderView: some View {
        HStack {
            // Left side: Location level for locations, device breakdown for devices, UTM parameter for UTM, otherwise item type
            if viewModel.selection.item == .locations {
                Menu {
                    locationLevelPicker
                } label: {
                    InlineValuePickerTitle(title: viewModel.selection.options.locationLevel.localizedTitle)
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 6)
                        .padding(.vertical, Constants.step0_5)
                }
                .fixedSize()
            } else if viewModel.selection.item == .devices {
                Menu {
                    deviceBreakdownPicker
                } label: {
                    InlineValuePickerTitle(title: viewModel.selection.options.deviceBreakdown.localizedTitle)
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 6)
                        .padding(.vertical, Constants.step0_5)
                }
                .fixedSize()
            } else if viewModel.selection.item == .utm {
                Menu {
                    utmParamGroupingPicker
                } label: {
                    InlineValuePickerTitle(title: viewModel.selection.options.utmParamGrouping.localizedTitle)
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 6)
                        .padding(.vertical, Constants.step0_5)
                }
                .fixedSize()
            } else {
                makeColumnTitle(viewModel.selection.item.localizedColumnName)
            }

            Spacer()

            // Right side: selected metric
            makeColumnTitle(viewModel.selection.metric.localizedTitle)
        }
    }

    private func makeColumnTitle(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(Color.secondary)
            .padding(.top, 6)
            .padding(.vertical, Constants.step0_5)
            .font(.subheadline)
            .fontWeight(.medium)
    }

    private func navigateToTopListScreen() {
        let screen = TopListScreenView(
            selection: viewModel.selection,
            dateRange: viewModel.dateRange,
            service: context.service,
            context: context,
            initialData: viewModel.data,
            filter: viewModel.filter
        )
        .environment(\.context, context)
        .environment(\.router, router)

        router.navigate(to: screen, title: viewModel.selection.item.localizedTitle)
    }

    private var itemTypePicker: some View {
        ForEach(Array(viewModel.groupedItems.enumerated()), id: \.offset) { _, items in
            Section {
                ForEach(items) { item in
                    Button {
                        var selection = viewModel.selection
                        selection.item = item
                        let supportedMetric = getSupportedMetrics(for: item)
                        if !supportedMetric.contains(selection.metric),
                           let metric = supportedMetric.first {
                            selection.metric = metric
                        }
                        viewModel.selection = selection
                    } label: {
                        Label(item.localizedTitle, systemImage: item.systemImage)
                    }
                }
            }
        }
        .tint(Color.primary)
    }

    private func makeMetricPicker(with metrics: [SiteMetric]) -> some View {
        ForEach(metrics) { metric in
            Button {
                viewModel.selection.metric = metric
            } label: {
                Label(metric.localizedTitle, systemImage: metric.systemImage)
            }
        }
        .tint(Color.primary)
    }

    private func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        context.service.getSupportedMetrics(for: item)
    }

    private var moreMenu: some View {
        Menu {
            moreMenuContent
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
    }

    @ViewBuilder
    private var moreMenuContent: some View {
        Section {
            if let documentationURL = viewModel.selection.item.documentationURL {
                Link(destination: documentationURL) {
                    Label(Strings.Buttons.learnMore, systemImage: "info.circle")
                }
            }
        }
        EditCardMenuContent(cardViewModel: viewModel)
    }

    private var locationLevelPicker: some View {
        ForEach(LocationLevel.allCases) { level in
            Button {
                let previousLevel = viewModel.selection.options.locationLevel
                viewModel.selection.options.locationLevel = level

                // Track location level change
                viewModel.tracker?.send(.locationLevelChanged, properties: [
                    "from_level": previousLevel.analyticsName,
                    "to_level": level.analyticsName
                ])
            } label: {
                Label(level.localizedTitle, systemImage: level.systemImage)
            }
        }
        .tint(Color.primary)
    }

    private var deviceBreakdownPicker: some View {
        ForEach(DeviceBreakdown.allCases) { breakdown in
            Button {
                let previousBreakdown = viewModel.selection.options.deviceBreakdown
                viewModel.selection.options.deviceBreakdown = breakdown

                // Track device breakdown change
                viewModel.tracker?.send(.deviceBreakdownChanged, properties: [
                    "from_breakdown": previousBreakdown.analyticsName,
                    "to_breakdown": breakdown.analyticsName
                ])
            } label: {
                Label(breakdown.localizedTitle, systemImage: breakdown.systemImage)
            }
        }
        .tint(Color.primary)
    }

    private var utmParamGroupingPicker: some View {
        ForEach(Array(UTMParamGrouping.grouped.enumerated()), id: \.offset) { _, groupings in
            Section {
                ForEach(groupings) { grouping in
                    Button {
                        let previousGrouping = viewModel.selection.options.utmParamGrouping
                        viewModel.selection.options.utmParamGrouping = grouping

                        // Track UTM parameter grouping change
                        viewModel.tracker?.send(.utmParamGroupingChanged, properties: [
                            "from_grouping": previousGrouping.analyticsName,
                            "to_grouping": grouping.analyticsName
                        ])
                    } label: {
                        Text(grouping.localizedTitle)
                    }
                }
            }
        }
        .tint(Color.primary)
    }

    @ViewBuilder
    private var listContentView: some View {
        Group {
            if viewModel.isFirstLoad {
                topListItemsView(data: mockData)
                    .allowsHitTesting(false)
                    .redacted(reason: .placeholder)
                    .pulsating()
            } else if let data = viewModel.data {
                if data.items.isEmpty {
                    makeEmptyStateView(message: Strings.Chart.empty)
                } else {
                    topListItemsView(data: data)
                }
            } else {
                makeEmptyStateView(message: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
            }
        }
    }

    private func topListItemsView(data: TopListData) -> some View {
        VStack(spacing: 0) {
            TopListItemsView(
                data: data,
                itemLimit: showMoreInline && isExpanded ? data.items.count : itemLimit,
                dateRange: viewModel.dateRange,
                reserveSpace: reserveSpace
            )
            if showMoreInline && data.items.count > itemLimit {
                showMoreInlineButton
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.step3)
            } else if !showMoreInline {
                showMoreButton
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.step3)
            }
        }
    }

    private var showMoreButton: some View {
        Button {
            navigateToTopListScreen()
        } label: {
            HStack(spacing: 4) {
                Text(Strings.Buttons.showAll)
                    .padding(.trailing, 4)
                    .font(.callout)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .font(.body)
        }
        .padding(.top, 16)
        .tint(Color.secondary.opacity(0.8))
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private var showMoreInlineButton: some View {
        Button {
            withAnimation(.spring) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(isExpanded ? Strings.Buttons.showLess : Strings.Buttons.showMore)
                    .padding(.trailing, 4)
                    .font(.callout)
                    .foregroundColor(.primary)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .center) // Expand tap area
        }
        .padding(.top, 16)
        .tint(Color.secondary.opacity(0.8))
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private func makeEmptyStateView(message: String) -> some View {
        topListItemsView(data: .init(item: viewModel.selection.item, metric: viewModel.selection.metric, items: []))
            .allowsHitTesting(false)
            .redacted(reason: .placeholder)
            .overlay {
                SimpleErrorView(message: message)
                    .offset(y: -18)
            }
    }

    private var mockData: TopListData {
        TopListData.mock(
            for: viewModel.selection.item,
            metric: viewModel.selection.metric,
            itemCount: itemLimit
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            TopListCardPreview(item: .utm)
            TopListCardPreview(item: .authors)
            TopListCardPreview(item: .locations)
        }
        .padding(.horizontal, 8)
    }
    .scrollContentBackground(.hidden)
    .background(Constants.Colors.background)
}

private struct TopListCardPreview: View {
    let item: TopListItemType

    @StateObject private var viewModel: TopListViewModel

    init(item: TopListItemType) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: TopListViewModel(
            configuration: TopListCardConfiguration(
                item: item,
                metric: item == .fileDownloads ? .downloads : .views
            ),
            dateRange: Calendar.demo.makeDateRange(for: .last28Days),
            service: MockStatsService(),
            tracker: MockStatsTracker.shared
        ))
    }

    var body: some View {
        TopListCard(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.background)
    }
}

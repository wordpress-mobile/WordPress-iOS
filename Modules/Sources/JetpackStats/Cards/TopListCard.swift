import SwiftUI

struct TopListCard: View {
    @ObservedObject private var viewModel: TopListViewModel

    private let itemLimit: Int
    private let reserveSpace: Bool

    @Environment(\.context) var context
    @Environment(\.router) var router

    init(
        viewModel: TopListViewModel,
        itemLimit: Int = 5,
        reserveSpace: Bool = true
    ) {
        self.viewModel = viewModel
        self.itemLimit = itemLimit
        self.reserveSpace = reserveSpace
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            cardHeaderView

            VStack(spacing: Constants.step1) {
                if viewModel.selection.item == .locations {
                    CountriesMapView(
                        data: viewModel.cachedCountriesMapData ?? .init(metric: viewModel.selection.metric, locations: []),
                        primaryColor: Constants.Colors.uiColorBlue
                    )
                    .padding(.vertical, Constants.step1)
                    .padding(.horizontal, Constants.step2)
                }

                listHeaderView
                    .padding(.horizontal, Constants.step3)

                listContentView
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .padding(.vertical, Constants.step2)
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .grayscale(viewModel.isStale ? 1 : 0)
        .animation(.smooth, value: viewModel.isStale)
        .animation(.spring, value: viewModel.data.map(ObjectIdentifier.init)) // placing is important
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    navigateToTopListScreen()
                }
        )
    }

    private var cardHeaderView: some View {
        HStack {
            StatsCardTitleView(title: viewModel.selection.item == .locations ? "Countries" : viewModel.title)
            Spacer(minLength: 44)
        }
        .padding(.horizontal, Constants.step3)
    }

    private var listHeaderView: some View {
        HStack {
            if viewModel.items.count > 1 {
                Menu {
                    itemTypePicker
                } label: {
                    InlineValuePickerTitle(title: viewModel.selection.item.localizedTitle)
                        .border(Color.red, width: 1)
                }
                .fixedSize()
            } else {
                Text(viewModel.selection.item.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            let metrics = getSupportedMetrics(for: viewModel.selection.item)
            if metrics.count > 1 {
                Menu {
                    makeMetricPicker(with: metrics)
                } label: {
                    InlineValuePickerTitle(title: viewModel.selection.metric.localizedTitle)
                        .border(Color.red, width: 1)
                }
                .fixedSize()
            } else {
                Text(viewModel.selection.metric.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }

    private func navigateToTopListScreen() {
        let screen = TopListScreenView(
            selection: viewModel.selection,
            dateRange: viewModel.dateRange,
            service: context.service,
            initialData: viewModel.data
        )
        .environment(\.context, context)
        .environment(\.router, router)

        router.navigate(to: screen)
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
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 56, height: 50)
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
        if let documentationURL = viewModel.selection.item.documentationURL {
            Section {
                Link(destination: documentationURL) {
                    Label(Strings.Buttons.learnMore, systemImage: "info.circle")
                }
            }
        }
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
                itemLimit: itemLimit,
                dateRange: viewModel.dateRange,
                reserveSpace: reserveSpace
            )
            showMoreButton
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Constants.step3)
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
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .font(.body)
        }
        .padding(.top, 16)
        .tint(Color.secondary.opacity(0.8))
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
    NavigationView {
        TopListCardPreview(item: .authors)
    }
}

private struct TopListCardPreview: View {
    let item: TopListItemType

    @StateObject private var viewModel: TopListViewModel

    init(item: TopListItemType) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: TopListViewModel(
            selection: .init(
                item: item,
                metric: item == .fileDownloads ? .downloads : .views
            ),
            dateRange: Calendar.demo.makeDateRange(for: .last28Days),
            service: MockStatsService()
        ))
    }

    var body: some View {
        TopListCard(viewModel: viewModel)
            .cardStyle()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.background)
    }
}

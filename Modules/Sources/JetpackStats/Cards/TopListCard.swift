import SwiftUI

struct TopListCard: View {
    @ObservedObject private var viewModel: TopListCardViewModel
    private let itemLimit: Int
    private let reserveSpace: Bool

    @Environment(\.context) var context


    init(
        viewModel: TopListCardViewModel,
        itemLimit: Int = 5,
        reserveSpace: Bool = true
    ) {
        self.viewModel = viewModel
        self.itemLimit = itemLimit
        self.reserveSpace = reserveSpace
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            HStack {
                StatsCardTitleView(title: viewModel.selection.item == .locations ? "Countries" : viewModel.title)
                Spacer(minLength: 44)
            }
            .padding(.horizontal, Constants.step3)

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
        .animation(.spring, value: viewModel.matchedData.map(ObjectIdentifier.init)) // placing is important
    }

    private var listHeaderView: some View {
        HStack {
            if viewModel.items.count > 1 {
                Menu {
                    itemTypePicker
                } label: {
                    InlineValuePickerTitle(title: viewModel.selection.item.localizedTitle)
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
                }
                .fixedSize()
            } else {
                Text(viewModel.selection.metric.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
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
    }

    @ViewBuilder
    private var listContentView: some View {
        Group {
            if viewModel.isFirstLoad {
                topListItemsView(data: mockData)
                    .redacted(reason: .placeholder)
                    .pulsating()
            } else if let data = viewModel.matchedData {
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

    private func topListItemsView(data: TopListChartData) -> some View {
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
            // Not implementd
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
        topListItemsView(data: mockData)
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
            itemCount: itemLimit
        )
    }
}

#Preview {
    TopListCardPreview(item: .authors)
}

private struct TopListCardPreview: View {
    let item: TopListItemType

    @StateObject private var viewModel: TopListCardViewModel

    init(item: TopListItemType) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: TopListCardViewModel(
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

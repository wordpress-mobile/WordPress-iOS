import SwiftUI
import DesignSystem
import UniformTypeIdentifiers
import WordPressUI

struct TopListScreenView: View {
    @StateObject private var viewModel: TopListViewModel
    @State private var isShowingAllItems = false

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
        List {
            Group {
                headerView
                    .background(Color(.secondarySystemBackground).opacity(0.7))
                    .cardStyle()
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)
                    .accessibilityElement(children: .contain)
                    .padding(.horizontal, Constants.step1)
                    .padding(.top, Constants.step1)

                Group {
                    if viewModel.isFirstLoad {
                        listContent(data: mockData())
                            .redacted(reason: .placeholder)
                            .pulsating()
                    } else if let data = viewModel.data {
                        if data.items.isEmpty {
                            makeEmptyStateView(message: Strings.Chart.empty)
                        } else {
                            listContent(data: data)
                        }
                    } else {
                        makeEmptyStateView(message: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
                    }
                }
                .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .animation(.default, value: viewModel.data.map(ObjectIdentifier.init))
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selection.metric.localizedTitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.primary)
                Text(context.formatters.dateRange.string(from: viewModel.dateRange.dateInterval))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Always show the metrics view to preserve identity
            metricsOverviewView(data: viewModel.data ?? mockData())
                .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
                .pulsating(viewModel.isFirstLoad)
                .animation(.smooth, value: viewModel.isFirstLoad)
        }
        .padding(.vertical, Constants.step2)
        .padding(.horizontal, Constants.step3)
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

    // MARK: - Lists

    enum ListSection {
        case top10
        case top50
        case other

        var title: String {
            switch self {
            case .top10: Strings.TopListTitles.top10
            case .top50: Strings.TopListTitles.top50
            case .other: ""
            }
        }
    }

    @ViewBuilder
    private func listContent(data: TopListData) -> some View {
        if data.items.count > 0 {
            listSection(.top10, data: data)
        }
        if data.items.count > 10 {
            listSection(.top50, data: data)
        }
        if data.items.count > 50 {
            if isShowingAllItems {
                listSection(.other, data: data)
            } else {
                showMoreButton
            }
        }
    }

    @ViewBuilder
    private func listSection(_ section: ListSection, data: TopListData) -> some View {
        if section == .other {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                Divider()
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, Constants.step1)
        } else {
            listHeaderView(title: section.title)
                .padding(EdgeInsets(top: Constants.step3, leading: Constants.step1, bottom: Constants.step0_5, trailing: Constants.step1))
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        listForEach(for: section, data: data)
            .grayscale(viewModel.isStale ? 1 : 0)
            .animation(.smooth, value: viewModel.isStale)
    }

    private func listHeaderView(title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text(viewModel.selection.metric.localizedTitle)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func listForEach(for section: ListSection, data: TopListData) -> some View {
        let items = getDisplayedItems(from: data.items, section: section)
        ForEach(items, id: \.element.id) { index, item in
            TopListItemView(
                index: index < 50 ? index : nil,
                item: item,
                previousValue: data.previousItem(for: item)?.metrics[viewModel.selection.metric],
                metric: viewModel.selection.metric,
                maxValue: data.metrics.maxValue,
                dateRange: viewModel.dateRange
            )
            .frame(height: TopListItemView.defaultCellHeight)
        }
        .listRowInsets(EdgeInsets(top: Constants.step0_5 / 2, leading: 0, bottom: Constants.step0_5 / 2, trailing: 0))
    }

    private func getDisplayedItems(
        from items: [any TopListItemProtocol],
        section: ListSection
    ) -> [(offset: Int, element: any TopListItemProtocol)] {
        switch section {
        case .top10:
            return Array(items.enumerated().prefix(10))
        case .top50:
            return Array(items.enumerated().prefix(50).dropFirst(10))
        case .other:
            return Array(items.enumerated().dropFirst(50))
        }
    }

    private var showMoreButton: some View {
        Button {
            withAnimation(.spring) {
                isShowingAllItems = true
            }
        } label: {
            HStack(spacing: 4) {
                Text(Strings.Buttons.showMore)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.step2)
    }

    private func makeEmptyStateView(message: String) -> some View {
        VStack {
            listContent(data: mockData(count: 6))
        }
        .redacted(reason: .placeholder)
        .grayscale(1)
        .opacity(0.25)
        .overlay {
            SimpleErrorView(message: message)
        }
    }

    private func mockData(count: Int = 10) -> TopListData {
        TopListData.mock(
            for: viewModel.selection.item,
            metric: viewModel.selection.metric,
            itemCount: count
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

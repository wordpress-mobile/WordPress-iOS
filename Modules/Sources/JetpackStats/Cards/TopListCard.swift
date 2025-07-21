import SwiftUI

struct TopListCard: View {
    @ObservedObject private var viewModel: TopListCardViewModel

    @Environment(\.context) var context

    private let itemLimit = 6

    init(viewModel: TopListCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatsCardTitleView(title: viewModel.title)
                Spacer(minLength: 44)
            }
            VStack(spacing: 12) {
                headerView
                contentView
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .padding(Constants.step2)
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .grayscale(viewModel.isStale ? 1 : 0)
        .animation(.smooth, value: viewModel.isStale)
    }

    private var headerView: some View {
        HStack {
            Menu {
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
            } label: {
                InlineValuePickerTitle(title: viewModel.selection.item.localizedTitle)
            }
            .fixedSize()

            Spacer()

            let metrics = getSupportedMetrics(for: viewModel.selection.item)
            if metrics.count > 1 {
                Menu {
                    ForEach(metrics) { metric in
                        Button {
                            viewModel.selection.metric = metric
                        } label: {
                            Label(metric.localizedTitle, systemImage: metric.systemImage)
                        }
                    }
                    .tint(Color.primary)
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
            ZStack(alignment: .top) {
                // Ensure consistent sizing
                TopListItemsView(data: mockData, itemLimit: itemLimit)
                    .opacity(0)
                TopListItemsView(data: data, itemLimit: itemLimit)
            }
            showMoreButton
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.caption)
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
        TopListChartData.mock(for: viewModel.selection.item, metric: viewModel.selection.metric, itemCount: itemLimit)
    }
}

#Preview {
    TopListCard(viewModel: TopListCardViewModel(
        selection: .init(
            item: .postsAndPages,
            metric: .views
        ),
        dateRange: Calendar.demo.makeDateRange(for: .last28Days),
        service: MockStatsService()
    ))
    .cardStyle()
    .padding()
}

import SwiftUI

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    let dateRange: StatsDateRange
    var showDetails = true

    @State private var expandedSections: Set<TopListItemID> = []

    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(data.items.prefix(itemLimit), id: \.id) { item in
                if let item = item as? any TopListExpandableItem {
                    makeExpandableSection(with: item)
                } else {
                    makeView(for: item)
                        .transition(.move(edge: .leading)
                            .combined(with: .scale(scale: 0.75))
                            .combined(with: .opacity))
                }
            }
        }
        .animation(.spring, value: ObjectIdentifier(data))
    }

    private func makeExpandableSection(with item: any TopListExpandableItem) -> some View {
        VStack(spacing: Constants.step1 / 2) {
            Button {
                withAnimation(.spring) {
                    toggleSection(item.id)
                }
            } label: {
                ExpandableItemView(
                    section: item,
                    previousItem: data.previousItem(for: item) as? (any TopListExpandableItem),
                    metric: data.metric,
                    maxValue: data.maxValue,
                    isExpanded: expandedSections.contains(item.id)
                )
            }
            .buttonStyle(.plain)

            if expandedSections.contains(item.id) {
                VStack(spacing: Constants.step1 / 2) {
                    ForEach(Array(item.children), id: \.id) { child in
                        makeView(for: child)
                            .padding(.leading, Constants.step2)
                            .transition(.move(edge: .leading)
                                .combined(with: .scale(scale: 0.75))
                                .combined(with: .opacity))
//                            .transition(.asymmetric(
//                                insertion: .opacity.combined(with: .move(edge: .top)),
//                                removal: .opacity.combined(with: .move(edge: .top))
//                            ))
                    }
                }
            }
        }
    }

    private func makeView(for item: any TopListItem) -> some View {
        TopListItemView(
            currentItem: item,
            previousItem: data.previousItem(for: item),
            metric: data.metric,
            maxValue: data.maxValue,
            showDetails: showDetails,
            dateRange: dateRange
        )
    }

    private func toggleSection(_ sectionId: TopListItemID) {
        if expandedSections.contains(sectionId) {
            expandedSections.remove(sectionId)
        } else {
            expandedSections.insert(sectionId)
        }
    }
}

// Generic view for expandable section headers that can show expanded state
private struct ExpandableItemView: View {
    let section: any TopListExpandableItem
    let previousItem: (any TopListExpandableItem)?
    let metric: SiteMetric
    let maxValue: Int
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 0) {
            TopListExpandableSectionRowView(
                item: section as any TopListExpandableItem,
                showDetails: false,
                isExpanded: isExpanded
            )

            Spacer(minLength: 4)

            TopListMetricsView(
                currentValue: section.metrics[metric] ?? 0,
                previousValue: previousItem?.metrics[metric],
                metric: metric,
                showDetails: false,
                showChevron: false
            )
        }
        .padding(.vertical, 7)
        .background(
            TopListItemBarBackground(
                value: section.metrics[metric] ?? 0,
                maxValue: maxValue,
                barColor: metric.primaryColor
            )
            .padding(.horizontal, -(Constants.step2 / 2))
        )
    }
}

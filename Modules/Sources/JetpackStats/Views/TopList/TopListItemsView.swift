import SwiftUI

// MARK: - View Extension for Conditional Modifiers
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    let dateRange: StatsDateRange
    var showDetails = true
    
    @State private var expandedSections: Set<String> = []

    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(Array(data.items.prefix(itemLimit))) { item in
                if let expandableItem = item.current as? any TopListExpandableItem {
                    // Expandable section with child items
                    VStack(spacing: Constants.step1 / 2) {
                        Button {
                            toggleSection(expandableItem.id)
                        } label: {
                            ExpandableItemView(
                                section: expandableItem,
                                previousItem: item.previous as? (any TopListExpandableItem),
                                metric: data.metric,
                                maxValue: data.maxValue,
                                dateRange: dateRange,
                                isExpanded: expandedSections.contains(expandableItem.id)
                            )
                        }
                        .buttonStyle(.plain)

                        // Expandable items
                        if expandedSections.contains(expandableItem.id) {
                            VStack(spacing: Constants.step1 / 2) {
                                ForEach(Array(expandableItem.items), id: \.id) { childItem in
                                    TopListItemView(
                                        currentItem: childItem,
                                        previousItem: nil,
                                        metric: data.metric,
                                        maxValue: data.maxValue,
                                        showDetails: showDetails,
                                        dateRange: dateRange
                                    )
                                    .padding(.leading, Constants.step2)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    ))
                                }
                            }
                        }
                    }
                } else {
                    makeItemView(for: item)
                        .transition(.move(edge: .leading)
                        .combined(with: .scale(scale: 0.75))
                        .combined(with: .opacity))
                }
            }
        }
        .animation(.spring, value: ObjectIdentifier(data))
        .animation(.spring, value: expandedSections)
    }

    private func makeItemView(for item: TopListChartData.Item) -> some View {
        TopListItemView(
            currentItem: item.current,
            previousItem: item.previous,
            metric: data.metric,
            maxValue: data.maxValue,
            showDetails: showDetails,
            dateRange: dateRange
        )
    }

    private func toggleSection(_ sectionId: String) {
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

import SwiftUI

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    let dateRange: StatsDateRange
    var showDetails = true
    
    @State private var expandedSections: Set<String> = []

    var body: some View {
        VStack(spacing: Constants.step1 / 2) {
            ForEach(data.items.prefix(itemLimit)) { item in
                if let archiveSection = item.current as? TopListData.ArchiveSection {
                    // Archive section with expandable items
                    VStack(spacing: Constants.step1 / 2) {
                        // Section header
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                toggleSection(archiveSection.id)
                            }
                        } label: {
                            ArchiveSectionItemView(
                                section: archiveSection,
                                previousItem: item.previous,
                                metric: data.metric,
                                maxValue: data.maxValue,
                                dateRange: dateRange,
                                isExpanded: expandedSections.contains(archiveSection.id)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Expandable items
                        if expandedSections.contains(archiveSection.id) {
                            VStack(spacing: Constants.step1 / 2) {
                                ForEach(archiveSection.items) { archiveItem in
                                    TopListItemView(
                                        currentItem: archiveItem,
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
                    // Regular item
                    TopListItemView(
                        currentItem: item.current,
                        previousItem: item.previous,
                        metric: data.metric,
                        maxValue: data.maxValue,
                        showDetails: showDetails,
                        dateRange: dateRange
                    )
                    .transition(.move(edge: .leading)
                        .combined(with: .scale(scale: 0.75))
                        .combined(with: .opacity))
                }
            }
        }
        .animation(.spring, value: ObjectIdentifier(data))
        .animation(.easeInOut(duration: 0.25), value: expandedSections)
    }
    
    private func toggleSection(_ sectionId: String) {
        if expandedSections.contains(sectionId) {
            expandedSections.remove(sectionId)
        } else {
            expandedSections.insert(sectionId)
        }
    }
}

// Custom view for archive section header that can show expanded state
private struct ArchiveSectionItemView: View {
    let section: TopListData.ArchiveSection
    let previousItem: (any TopListItem)?
    let metric: SiteMetric
    let maxValue: Int
    let dateRange: StatsDateRange
    let isExpanded: Bool
    
    @Environment(\.router) private var router
    @Environment(\.context) private var context

    var body: some View {
        HStack(spacing: 0) {
            TopListArchiveSectionRowView(
                item: section,
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

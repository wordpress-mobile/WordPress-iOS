import SwiftUI
import DesignSystem

struct ArchiveStatsView: View {
    let archiveSection: TopListItem.ArchiveSection
    let dateRange: StatsDateRange
    
    @Environment(\.context) private var context
    @Environment(\.router) private var router
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                headerCard
                if !archiveSection.items.isEmpty {
                    itemsCard
                }
            }
            .padding(.vertical, Constants.step1)
        }
        .background(Constants.Colors.background)
        .navigationTitle(archiveSection.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var headerCard: some View {
        VStack(spacing: Constants.step2) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(archiveSection.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(Strings.ArchiveSections.itemCount(archiveSection.items.count))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let totalViews = archiveSection.metrics.views {
                    StandaloneMetricView(metric: .views, value: totalViews)
                }
            }
        }
        .padding(Constants.step2)
        .cardStyle()
    }
    
    var itemsCard: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            Text(itemsTitle)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, Constants.step3)

            TopListItemsView(
                data: itemsChartData,
                itemLimit: archiveSection.items.count,
                dateRange: dateRange
            )
        }
        .padding(.vertical, Constants.step2)
        .cardStyle()
    }
    
    private var itemsTitle: String {
        switch archiveSection.sectionName.lowercased() {
        case "author":
            return Strings.ArchiveSections.author
        case "other":
            return Strings.ArchiveSections.other
        default:
            return archiveSection.displayName
        }
    }
    
    private var itemsChartData: TopListChartData {
        return TopListChartData(
            item: .archive,
            metric: .views,
            items: archiveSection.items
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ArchiveStatsView(
            archiveSection: .mock,
            dateRange: Calendar.demo.makeDateRange(for: .thisMonth)
        )
    }
    .tint(Constants.Colors.jetpack)
}

private extension TopListItem.ArchiveSection {
    static let mock = TopListItem.ArchiveSection(
        sectionName: "author",
        items: [
            TopListItem.ArchiveItem(
                href: "/author/john-doe/",
                value: "John Doe",
                metrics: SiteMetricsSet(views: 5000)
            ),
            TopListItem.ArchiveItem(
                href: "/author/jane-smith/",
                value: "Jane Smith",
                metrics: SiteMetricsSet(views: 4200)
            ),
            TopListItem.ArchiveItem(
                href: "/author/mike-jones/",
                value: "Mike Jones",
                metrics: SiteMetricsSet(views: 3100)
            )
        ],
        metrics: SiteMetricsSet(views: 12300)
    )
}

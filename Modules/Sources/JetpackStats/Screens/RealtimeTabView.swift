import SwiftUI

struct RealtimeTabView: View {
    @State private var dateRangeComparison = StatsDateRange(
        interval: {
            let now = Date()
            let thirtyMinutesAgo = now.addingTimeInterval(-30 * 60)
            return DateInterval(start: thirtyMinutesAgo, end: now)
        }(),
        component: .day
    )

    @Environment(\.context) var context

    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                realtimeStatsCard
                Text("Showing Mock Data")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                realtimeTopPosts
                realtimeTopReferrers
                realtimeTopLocations
            }
            .padding(.vertical, Constants.step2)
        }
        .onReceive(timer) { _ in
            updateDateRange()
        }
    }

    private var realtimeStatsCard: some View {
        RealtimeMetricsCard()
            .cardStyle()
    }

    private var realtimeTopPosts: some View {
        RealtimeTopListCard(
            initialDataType: .postsAndPages,
            service: context.service
        )
        .cardStyle()
    }

    private var realtimeTopReferrers: some View {
        RealtimeTopListCard(
            initialDataType: .referrers,
            service: context.service
        )
        .cardStyle()
    }

    private var realtimeTopLocations: some View {
        RealtimeTopListCard(
            initialDataType: .locations,
            service: context.service
        )
        .cardStyle()
    }

    private func updateDateRange() {
        let now = Date()
        let thirtyMinutesAgo = now.addingTimeInterval(-30 * 60)
        dateRangeComparison = StatsDateRange(
            interval: DateInterval(start: thirtyMinutesAgo, end: now),
            component: .day
        )
    }
}

// MARK: - Preview

#Preview {
    RealtimeTabView()
}

import SwiftUI

struct RealtimeTabView: View {
    @Environment(\.context) var context

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
}

// MARK: - Preview

#Preview {
    RealtimeTabView()
}

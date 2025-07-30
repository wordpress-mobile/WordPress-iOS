import SwiftUI

struct RealtimeTabView: View {
    @Environment(\.context) var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ScaledMetric private var maxWidth = 720

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
            .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            .padding(.vertical, Constants.step2)
            .frame(maxWidth: maxWidth, alignment: .center)
            .frame(maxWidth: maxWidth)
        }
        .background(Constants.Colors.background)
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

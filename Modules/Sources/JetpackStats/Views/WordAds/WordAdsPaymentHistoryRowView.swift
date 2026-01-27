import SwiftUI
@preconcurrency import WordPressKit

struct WordAdsPaymentHistoryRowView: View {
    let viewModel: WordAdsPaymentHistoryRowViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Period and Status
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.formattedPeriod)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                statusBadge
            }

            Spacer(minLength: 6)

            // Metrics
            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedAmount)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(viewModel.formattedAdsServed)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Text(viewModel.statusText)
                .font(.caption2.weight(.medium))
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    List {
        WordAdsPaymentHistoryRowView(
            viewModel: WordAdsPaymentHistoryRowViewModel(
                earning: StatsWordAdsEarningsResponse.MonthlyEarning(
                    period: StatsWordAdsEarningsResponse.Period(year: 2025, month: 12),
                    data: StatsWordAdsEarningsResponse.MonthlyEarningData(
                        amount: 15.25,
                        status: .outstanding,
                        pageviews: "3420"
                    )
                )
            )
        )

        WordAdsPaymentHistoryRowView(
            viewModel: WordAdsPaymentHistoryRowViewModel(
                earning: StatsWordAdsEarningsResponse.MonthlyEarning(
                    period: StatsWordAdsEarningsResponse.Period(year: 2025, month: 8),
                    data: StatsWordAdsEarningsResponse.MonthlyEarningData(
                        amount: 5.50,
                        status: .paid,
                        pageviews: "1200"
                    )
                )
            )
        )
    }
    .listStyle(.plain)
}

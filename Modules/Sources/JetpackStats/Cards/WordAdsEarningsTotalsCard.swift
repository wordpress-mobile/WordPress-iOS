import SwiftUI
import WordPressKit

struct WordAdsEarningsTotalsCard: View {
    @ObservedObject var viewModel: WordAdsEarningsViewModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            StatsCardTitleView(title: Strings.WordAds.totalEarnings)

            EarningsMetricsStrip(data: metricsData)
                .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
        }
        .padding(Constants.step2)
        .cardStyle()
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
    }

    private var moreMenu: some View {
        Menu {
            Link(destination: URL(string: "https://wordpress.com/support/wordads-and-earn/track-your-ads/")!) {
                Label(Strings.WordAds.learnMore, systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
    }

    private var metricsData: EarningsMetricsData? {
        if let earnings = viewModel.earnings {
            return EarningsMetricsData(
                totalEarnings: earnings.totalEarnings,
                paid: earnings.totalEarnings - earnings.totalAmountOwed,
                outstanding: earnings.totalAmountOwed
            )
        } else if viewModel.isFirstLoad {
            return .mockData
        } else {
            return nil
        }
    }
}

// MARK: - Earnings Metrics Strip

private struct EarningsMetricsStrip: View {
    let data: EarningsMetricsData?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.step3) {
                MetricView(
                    title: Strings.WordAds.earnings,
                    value: data?.totalEarnings
                )
                MetricView(
                    title: Strings.WordAds.paid,
                    value: data?.paid
                )
                MetricView(
                    title: Strings.WordAds.outstanding,
                    value: data?.outstanding
                )
            }
        }
    }

    struct MetricView: View {
        let title: String
        let value: Decimal?

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                Text(displayValue)
                    .contentTransition(.numericText())
                    .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                    .foregroundColor(.primary)
                    .animation(.spring, value: displayValue)
            }
            .lineLimit(1)
            .frame(minWidth: 78, alignment: .leading)
        }

        private var displayValue: String {
            guard let value else { return "–" }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = 2
            return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
        }
    }
}

// MARK: - Data Models

private struct EarningsMetricsData {
    let totalEarnings: Decimal
    let paid: Decimal
    let outstanding: Decimal

    /// Mock data used for loading state placeholders
    static let mockData = EarningsMetricsData(
        totalEarnings: 42.67,
        paid: 4.27,
        outstanding: 38.40
    )
}

#Preview {
    @Previewable @StateObject var viewModel = WordAdsEarningsViewModel(service: MockStatsService())

    return VStack {
        WordAdsEarningsTotalsCard(viewModel: viewModel)
    }
    .padding()
}

import SwiftUI
import WordPressKit

struct WordAdsEarningsTotalsCard: View {
    @ObservedObject var viewModel: WordAdsEarningsViewModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatsCardTitleView(title: Strings.WordAds.totalEarnings)

            VStack(alignment: .leading, spacing: Constants.step1) {
                Text(totalEarningsValue)
                    .contentTransition(.numericText())
                    .font(Constants.Typography.largeDisplayFont)
                    .kerning(Constants.Typography.largeDisplayKerning)
                    .foregroundColor(.primary)
                    .animation(.spring, value: totalEarningsValue)

                HStack(spacing: Constants.step4) {
                    SecondaryMetricView(
                        title: Strings.WordAds.paid,
                        value: metricsData?.paid
                    )

                    SecondaryMetricView(
                        title: Strings.WordAds.outstanding,
                        value: metricsData?.outstanding
                    )
                }
            }
            .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var totalEarningsValue: String {
        guard let value = metricsData?.totalEarnings else { return "–" }
        return value.formatted(.currency(code: "USD"))
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

// MARK: - Secondary Metric View

private struct SecondaryMetricView: View {
    let title: String
    let value: Decimal?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(displayValue)
                .contentTransition(.numericText())
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .animation(.spring, value: displayValue)
        }
        .lineLimit(1)
    }

    private var displayValue: String {
        guard let value else { return "–" }
        return value.formatted(.currency(code: "USD"))
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

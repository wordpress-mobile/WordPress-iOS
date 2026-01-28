import SwiftUI
@preconcurrency import WordPressKit

struct WordAdsPaymentHistoryCard: View {
    @ObservedObject var viewModel: WordAdsEarningsViewModel

    @Environment(\.router) private var router
    @Environment(\.context) private var context

    private let itemLimit = 6

    private var mockViewModels: [WordAdsPaymentHistoryRowViewModel] {
        (0..<5).map { index in
            WordAdsPaymentHistoryRowViewModel(
                earning: StatsWordAdsEarningsResponse.MonthlyEarning(
                    period: StatsWordAdsEarningsResponse.Period(year: 2025, month: 12 - index),
                    data: StatsWordAdsEarningsResponse.MonthlyEarningData(
                        amount: 15.25,
                        status: .outstanding,
                        pageviews: "3420"
                    )
                )
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatsCardTitleView(title: Strings.WordAds.paymentsHistory)
                .padding(.horizontal, Constants.step3)
                .padding(.bottom, Constants.step1)

            if viewModel.isFirstLoad {
                loadingView
            } else if let earnings = viewModel.earnings, !earnings.wordAdsEarnings.isEmpty {
                let rowViewModels = earnings.wordAdsEarnings.prefix(itemLimit).map {
                    WordAdsPaymentHistoryRowViewModel(earning: $0)
                }
                contentView(viewModels: Array(rowViewModels), hasMore: earnings.wordAdsEarnings.count > itemLimit)
            } else if let loadingError = viewModel.loadingError {
                errorView(error: loadingError)
            } else {
                emptyView
            }
        }
        .padding(.vertical, Constants.step2)
        .cardStyle()
    }

    private var loadingView: some View {
        contentView(viewModels: mockViewModels, hasMore: false)
            .redacted(reason: .placeholder)
            .pulsating()
    }

    private var emptyView: some View {
        Text(Strings.WordAds.noPaymentsYet)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Constants.step3)
    }

    private func errorView(error: Error) -> some View {
        contentView(viewModels: mockViewModels, hasMore: false)
            .redacted(reason: .placeholder)
            .grayscale(1)
            .opacity(0.1)
            .overlay {
                SimpleErrorView(error: error)
            }
    }

    private func contentView(viewModels: [WordAdsPaymentHistoryRowViewModel], hasMore: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModels.enumerated()), id: \.offset) { index, viewModel in
                WordAdsPaymentHistoryRowView(viewModel: viewModel)
                    .padding(.horizontal, Constants.step3)
                    .padding(.vertical, 9)

                if index < viewModels.count - 1 {
                    Divider()
                        .padding(.leading, Constants.step3)
                }
            }

            if hasMore {
                showMoreButton
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.step3)
            }
        }
    }

    private var showMoreButton: some View {
        Button {
            navigateToPaymentHistory()
        } label: {
            HStack(spacing: 4) {
                Text(Strings.Buttons.showAll)
                    .padding(.trailing, 4)
                    .font(.callout)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 16)
        .tint(Color.secondary.opacity(0.8))
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private func navigateToPaymentHistory() {
        guard let earnings = viewModel.earnings else { return }

        router.navigate(
            to: WordAdsPaymentHistoryView(earnings: earnings),
            title: Strings.WordAds.paymentsHistory
        )
    }
}

#Preview {
    @Previewable @StateObject var viewModel = WordAdsEarningsViewModel(service: MockStatsService())

    return VStack {
        WordAdsPaymentHistoryCard(viewModel: viewModel)
    }
    .padding()
}

import SwiftUI
import WordPressKit
import WordPressUI

public struct AdsTabView: View {
    @StateObject private var chartViewModel: WordAdsChartCardViewModel
    @StateObject private var earningsViewModel: WordAdsEarningsViewModel

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private let context: StatsContext
    private let router: StatsRouter

    public init(context: StatsContext, router: StatsRouter) {
        self.context = context
        self.router = router
        _chartViewModel = StateObject(
            wrappedValue: WordAdsChartCardViewModel(service: context.service)
        )
        _earningsViewModel = StateObject(
            wrappedValue: WordAdsEarningsViewModel(service: context.service)
        )
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                WordAdsEarningsTotalsCard(viewModel: earningsViewModel)
                WordAdsChartCard(viewModel: chartViewModel)
                WordAdsPaymentHistoryCard(viewModel: earningsViewModel)
            }
            .padding(.vertical, Constants.step2)
            .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            .padding(.top, Constants.step0_5)
        }
        .background(Constants.Colors.background)
        .environment(\.context, context)
        .environment(\.router, router)
        .onAppear {
            context.tracker?.send(.adsTabShown)
        }
        .task {
            await earningsViewModel.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        AdsTabView(
            context: .demo,
            router: StatsRouter(
                viewController: UINavigationController(),
                factory: MockStatsRouterScreenFactory()
            )
        )
    }
}

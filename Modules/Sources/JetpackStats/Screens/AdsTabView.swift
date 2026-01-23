import SwiftUI

public struct AdsTabView: View {
    @StateObject private var viewModel: WordAdsChartCardViewModel

    public init(context: StatsContext, router: StatsRouter) {
        _viewModel = StateObject(
            wrappedValue: WordAdsChartCardViewModel(service: context.service)
        )
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                WordAdsChartCard(viewModel: viewModel)
            }
            .padding(.vertical, Constants.step2)
            .padding(.horizontal, Constants.step1)
            .padding(.top, Constants.step0_5)
        }
        .background(Constants.Colors.background)
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
        .environment(\.context, .demo)
    }
}

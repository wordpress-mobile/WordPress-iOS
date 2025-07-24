import SwiftUI

public struct StatsMainView: View {
    @State private var selectedTab = StatsTab.traffic
    @State private var isTabBarBackgroundShown = true

    private let context: StatsContext
    private let router: StatsRouter

    public init(context: StatsContext, router: StatsRouter) {
        self.context = context
        self.router = router
    }

    public var body: some View {
        tabContent
            .id(selectedTab)
            .trackScrollOffset(isScrolling: $isTabBarBackgroundShown)
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                StatsTabBar(selectedTab: $selectedTab, showBackground: isTabBarBackgroundShown)
            }
            .background(Constants.Colors.background)
            .navigationTitle(Strings.stats)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.context, context)
            .environment(\.router, router)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .traffic:
            TrafficTabView(dateRange: makeDefaultDateRange())
        case .realtime:
            RealtimeTabView()
        case .insights:
            InsightsTabView()
        case .subscribers:
            SubscribersTabView()
        }
    }

    private func makeDefaultDateRange() -> StatsDateRange {
        context.calendar.makeDateRange(for: .today)
    }
}

#Preview {
    PreviewStatsMainView()
        .ignoresSafeArea()
}

private struct PreviewStatsMainView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let router = StatsRouter(viewController: navigationController, factory: MockStatsRouterScreenFactory())
        let view = StatsMainView(context: .demo, router: router)
        let hostingController = UIHostingController(rootView: view)
        navigationController.viewControllers = [hostingController]
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
}

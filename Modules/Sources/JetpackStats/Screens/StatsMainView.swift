import SwiftUI

public struct StatsMainView: View {
    @StateObject private var viewModel: StatsViewModel

    @State private var selectedTab = StatsTab.traffic
    @State private var isTabBarBackgroundShown = true

    private let context: StatsContext
    private let router: StatsRouter
    private let showTabs: Bool

    public init(context: StatsContext, router: StatsRouter, showTabs: Bool = true) {
        self.context = context
        self.router = router
        self.showTabs = showTabs

        let viewModel = StatsViewModel(context: context)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        if showTabs {
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
                .onAppear {
                    context.tracker?.send(.statsMainScreenShown)
                }
                .onChange(of: selectedTab) { newValue in
                    trackTabChange(from: selectedTab, to: newValue)
                }
        } else {
            // When tabs are hidden, show only traffic tab without the tab bar
            TrafficTabView(viewModel: viewModel, topPadding: Constants.step1)
                .background(Constants.Colors.background)
                .environment(\.context, context)
                .environment(\.router, router)
                .onAppear {
                    context.tracker?.send(.statsMainScreenShown)
                }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .traffic:
            TrafficTabView(viewModel: viewModel)
                .onAppear {
                    context.tracker?.send(.trafficTabShown)
                }
        case .realtime:
            RealtimeTabView()
                .onAppear {
                    context.tracker?.send(.realtimeTabShown)
                }
        case .insights:
            InsightsTabView()
        case .subscribers:
            SubscribersTabView()
                .onAppear {
                    context.tracker?.send(.subscribersTabShown)
                }
        }
    }

    private func trackTabChange(from oldTab: StatsTab, to newTab: StatsTab) {
        context.tracker?.send(.statsTabSelected, properties: [
            "tab_name": newTab.analyticsName,
            "previous_tab": oldTab.analyticsName
        ])
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

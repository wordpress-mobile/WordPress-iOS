import SwiftUI

public struct StatsMainView: View {
    @State private var selectedTab = StatsTab.traffic
    @State private var isTabBarBackgroundShown = true

    private let context: StatsContext

    public init(context: StatsContext) {
        self.context = context
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
    NavigationPreview {
        StatsMainView(context: .demo)
    }
    .ignoresSafeArea()
}

private struct NavigationPreview<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let router = StatsRouter(navigationController: navigationController)

        let hostingController = UIHostingController(
            rootView: content()
                .environment(\.router, router)
        )

        navigationController.viewControllers = [hostingController]
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
}

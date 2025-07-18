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
            .background(Constants.Colors.statsBackground)
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
    NavigationStack {
        StatsMainView(context: .demo)
    }
}

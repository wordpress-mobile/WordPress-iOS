import SwiftUI

enum StatsTab: CaseIterable {
    case traffic
    case realtime
    case insights
    case subscribers

    var localizedTitle: String {
        switch self {
        case .traffic: return Strings.Tabs.traffic
        case .realtime: return Strings.Tabs.realtime
        case .insights: return Strings.Tabs.insights
        case .subscribers: return Strings.Tabs.subscribers
        }
    }

    var analyticsName: String {
        switch self {
        case .traffic: return "traffic"
        case .realtime: return "realtime"
        case .insights: return "insights"
        case .subscribers: return "subscribers"
        }
    }
}

struct StatsTabBar: View {
    @Binding var selectedTab: StatsTab
    var showBackground: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(StatsTab.allCases, id: \.self) { tab in
                        tabButton(for: tab)
                    }
                }
                .padding(.horizontal, Constants.step4)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Strings.Accessibility.statsTabBar)
            Divider()
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(.top, 8)
        .background {
            backgroundView
        }
    }

    @ViewBuilder
    private func tabButton(for tab: StatsTab) -> some View {
        Button(action: {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            UIAccessibility.post(notification: .announcement, argument: Strings.Accessibility.tabSelected(tab.localizedTitle))
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Reserver enough space for the semibold version
                    Text(tab.localizedTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .opacity(selectedTab == tab ? 1 : 0)

                    Text(tab.localizedTitle)
                        .font(.headline.weight(.regular))
                        .foregroundColor(.secondary)
                        .opacity(selectedTab == tab ? 0 : 1)
                }

                Rectangle()
                    .fill(selectedTab == tab ? Color.primary : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1.5)
            }
            .animation(.smooth, value: selectedTab)
        }
        .accessibilityLabel(tab.localizedTitle)
        .accessibilityHint(Strings.Accessibility.selectTab(tab.localizedTitle))
        .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
    }

    private var backgroundView: some View {
        Rectangle()
            .fill(Material.ultraThin)
            .ignoresSafeArea(edges: .top)
            .frame(maxHeight: .infinity)
            .offset(y: -100)
            .padding(.bottom, -100)
            .opacity(showBackground ? 1 : 0)
    }
}

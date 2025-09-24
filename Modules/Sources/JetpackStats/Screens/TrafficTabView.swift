import SwiftUI

struct TrafficTabView: View {
    @ObservedObject var viewModel: StatsViewModel

    @State private var isShowingCustomRangePicker = false
    @State private var isShowingAddCardSheet = false

    @Environment(\.context) var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Temporary workaround while we are still showing this in the existing UIKit screens.
    private let topPadding: CGFloat

    init(viewModel: StatsViewModel, topPadding: CGFloat = 0) {
        self.viewModel = viewModel
        self.topPadding = topPadding
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Constants.step3) {
                    cards
                    buttonAddChart
                    timeZoneInfo
                }
                .padding(.vertical, Constants.step2)
                .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
                .padding(.top, topPadding)
                .onReceive(viewModel.scrollToCardSubject) { cardID in
                    // Use a more elegant spring animation for scrolling
                    withAnimation(.spring) {
                        proxy.scrollTo(cardID, anchor: .top)
                    }
                }
            }
            .background(Constants.Colors.background)
            .animation(.spring, value: viewModel.cards.map(\.id))
            .listStyle(.plain)
        }
        .toolbar {
            if horizontalSizeClass == .regular {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    StatsDateRangeButtons(dateRange: $viewModel.dateRange)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if horizontalSizeClass == .compact {
                LegacyFloatingDateControl(dateRange: $viewModel.dateRange)
            }
        }
        .sheet(isPresented: $isShowingCustomRangePicker) {
            CustomDateRangePicker(dateRange: $viewModel.dateRange)
        }
    }

    @ViewBuilder
    private var cards: some View {
        if horizontalSizeClass == .regular {
            var cards = viewModel.cards
            if let first = cards.first as? ChartCardViewModel {
                let _ = cards.removeFirst()
                cardView(for: first)
            }
            HStack(alignment: .top, spacing: Constants.step2) {
                VStack(spacing: Constants.step3) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        if index % 2 == 0 {
                            cardView(for: card)
                        }
                    }
                }
                VStack(spacing: Constants.step3) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        if index % 2 == 1 {
                            cardView(for: card)
                        }
                    }
                }
            }
        } else {
            ForEach(viewModel.cards, id: \.id) { card in
                cardView(for: card)
            }
        }
    }

    @ViewBuilder
    private func makeItem(for viewModel: TrafficCardViewModel) -> some View {
        switch viewModel {
        case let viewModel as ChartCardViewModel:
            ChartCard(viewModel: viewModel)
                .onDateRangeSelected { dateRange in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.viewModel.pushDateRange(dateRange)
                }
                .backButton(title: getBackButtonTitle()) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.viewModel.popDateRange()
                }
        case let viewModel as TopListViewModel:
            TopListCard(viewModel: viewModel)
        default:
            let _ = assertionFailure("Unsupported type: \(viewModel)")
            EmptyView()
        }
    }

    private func getBackButtonTitle() -> String? {
        guard let range = viewModel.dateRangeNavigationStack.last else {
            return nil
        }
        let formatter = StatsDateRangeFormatter(timeZone: context.timeZone)
        return formatter.string(from: range.dateInterval)
    }

    @ViewBuilder
    private func cardView(for card: TrafficCardViewModel) -> some View {
        makeItem(for: card)
            .id(card.id)
            .transition(.asymmetric(
                insertion: .push(from: .bottom).combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
    }

    // MARK: - Misc

    private var buttonAddChart: some View {
        // Add Chart Button
        Button(action: {
            isShowingAddCardSheet = true
        }) {
            HStack(spacing: Constants.step1) {
                Image(systemName: "plus")
                    .font(.headline)
                Text(Strings.Buttons.addCard)
                    .font(.headline)
            }
            .foregroundColor(.secondary)
            .padding(3)
        }
        .accessibilityLabel(Strings.Accessibility.addCardButton)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .popover(isPresented: $isShowingAddCardSheet) {
            AddCardSheet { cardType in
                viewModel.addCard(type: cardType)
            }
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .presentationCompactAdaptation(.popover)
        }
    }

    private var timeZoneInfo: some View {
        TimezoneInfoView()
            .padding(.horizontal, Constants.step4)
            .padding(.top, Constants.step2)
            .padding(.bottom, Constants.step1)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

#Preview {
    NavigationView {
        TrafficTabView(viewModel: StatsViewModel(context: .demo))
    }
    .environment(\.context, .demo)
    .environment(\.router, StatsRouter(viewController: UINavigationController(), factory: MockStatsRouterScreenFactory()))
}

import SwiftUI

struct TrafficTabView: View {
    @ObservedObject var viewModel: StatsViewModel

    @State private var isShowingCustomRangePicker = false
    @State private var isShowingAddCardSheet = false
    @State private var isShowingColumns = false

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
            .refreshable {
                for card in viewModel.cards {
                    card.dateRange = viewModel.dateRange
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onGeometryChange(for: Bool.self, of: { proxy in
            proxy.size.width > 680
        }, action: {
            isShowingColumns = $0
        })
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
            CustomDateRangePicker(dateRange: Binding(
                get: { viewModel.dateRange.range },
                set: { viewModel.dateRange = StatsDateRangeSelection(range: $0) }
            ))
        }
    }

    @ViewBuilder
    private var cards: some View {
        if isShowingColumns {
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
    private func cardView(for card: TrafficCardViewModel) -> some View {
        makeItem(for: card)
            .id(card.id)
            .transition(.asymmetric(
                insertion: .push(from: .bottom).combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
    }

    @ViewBuilder
    private func makeItem(for viewModel: TrafficCardViewModel) -> some View {
        switch viewModel {
        case let viewModel as ChartCardViewModel:
            ChartCard(viewModel: viewModel)
        case let viewModel as TopListViewModel:
            TopListCard(viewModel: viewModel)
        case let viewModel as TodayCardViewModel:
            Button {
                context.tracker?.send(.todayCardTapped)
                self.viewModel.handleTodayCardTap()
            } label: {
                TodayCard(viewModel: viewModel)
            }
            .buttonStyle(.plain)
        default:
            let _ = assertionFailure("Unsupported type: \(viewModel)")
            EmptyView()
        }
    }

    // MARK: - Misc

    private var buttonAddChart: some View {
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
    }
}

#Preview {
    NavigationView {
        TrafficTabView(viewModel: StatsViewModel(context: .demo))
    }
    .environment(\.context, .demo)
    .environment(\.router, StatsRouter(viewController: UINavigationController(), factory: MockStatsRouterScreenFactory()))
}

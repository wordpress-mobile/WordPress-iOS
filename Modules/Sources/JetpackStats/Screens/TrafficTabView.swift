import SwiftUI

struct TrafficTabView: View {
    @ObservedObject var viewModel: StatsViewModel

    @State private var isShowingCustomRangePicker = false
    @State private var isShowingAddCardSheet = false

    @Environment(\.context) var context

    init(viewModel: StatsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Constants.step3) {
                    ForEach(viewModel.cards, id: \.id) { card in
                        makeItem(for: card)
                            .id(card.id)
                            .transition(.asymmetric(
                                insertion: .push(from: .bottom).combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                    buttonAddChart
                    timeZoneInfo
                }
                .padding(.vertical, Constants.step2)
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
//          normalModeToolbarContent
        }
        .safeAreaInset(edge: .bottom) {
            LegacyFloatingDateControl(dateRange: $viewModel.dateRange)
        }
        .sheet(isPresented: $isShowingCustomRangePicker) {
            CustomDateRangePicker(dateRange: $viewModel.dateRange)
        }
    }

    @ViewBuilder
    private func makeItem(for viewModel: TrafficCardViewModel) -> some View {
        switch viewModel {
        case let viewModel as ChartCardViewModel:
            ChartCard(viewModel: viewModel)
        case let viewModel as TopListViewModel:
            TopListCard(viewModel: viewModel)
        default:
            let _ = assertionFailure("Unsupported type: \(viewModel)")
            EmptyView()
        }
    }

    private var buttonAddChart: some View{
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
            .padding(Constants.step0_5)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .scaleEffect(isShowingAddCardSheet ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isShowingAddCardSheet)
        .padding(.top, Constants.step1)
        .popover(isPresented: $isShowingAddCardSheet) {
            AddCardSheet { cardType in
                viewModel.addCard(type: cardType)
            }
            .modifier(PopoverPresentationModifier())
        }
    }

    private var timeZoneInfo: some View {
        TimezoneInfoView()
            .padding(.horizontal, Constants.step4)
            .padding(.top, Constants.step2)
            .padding(.bottom, Constants.step1)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var normalModeToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            datePickerToolbarItem
            Spacer()
            makeNavigationButton(direction: .backward)
            makeNavigationButton(direction: .forward)
        }
    }

    private func makeNavigationButton(direction: Calendar.NavigationDirection) -> some View {
        Menu {
            ForEach(viewModel.dateRange.availableAdjacentPeriods(in: direction)) { period in
                Button(period.displayText) {
                    viewModel.dateRange = period.range
                }
            }
        } label: {
            Image(systemName: direction.systemImage)
        } primaryAction: {
            viewModel.dateRange = viewModel.dateRange.navigate(direction)
        }
        .disabled(!viewModel.dateRange.canNavigate(in: direction))
        .tint(.primary)
    }

    // MARK: - Date Picker

    private var datePickerToolbarItem: some View {
        Menu {
            StatsDateRangePickerMenu(selection: $viewModel.dateRange, isShowingCustomRangePicker: $isShowingCustomRangePicker)
        } label: {
            datePickerLabel
        }
        .menuOrder(.fixed)
        .tint(.primary)
    }

    private var datePickerLabel: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.subheadline)
            Text(context.formatters.dateRange.string(from: viewModel.dateRange.dateInterval))
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
    }
}

#Preview {
    NavigationView {
        TrafficTabView(
            viewModel: StatsViewModel(context: .demo, initialDateRange: Calendar.demo.makeDateRange(for: .today))
        )
    }
    .environment(\.context, .demo)
    .environment(\.router, StatsRouter(viewController: UINavigationController(), factory: MockStatsRouterScreenFactory()))
}

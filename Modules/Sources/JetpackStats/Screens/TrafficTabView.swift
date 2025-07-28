import SwiftUI

struct TrafficTabView: View {
    @State private var isShowingCustomRangePicker = false
    @ObservedObject var viewModel: StatsViewModel

    @Environment(\.context) var context

    init(viewModel: StatsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                ForEach(viewModel.cards, id: \.id) { card in
                    makeItem(for: card)
                }
                TimezoneInfoView()
                    .padding(.horizontal, Constants.step4)
                    .padding(.top, Constants.step2)
                    .padding(.bottom, Constants.step1)
            }
            .padding(.vertical, Constants.step2)
        }
        .listStyle(.plain)
        .background(Constants.Colors.background)
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
                .cardStyle()
        case let viewModel as TopListViewModel:
            TopListCard(viewModel: viewModel)
                .cardStyle()
        default:
            let _ = assertionFailure("Unsupported type: \(viewModel)")
            EmptyView()
        }
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

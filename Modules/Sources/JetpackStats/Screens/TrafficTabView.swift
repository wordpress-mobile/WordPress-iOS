import SwiftUI

struct TrafficTabView: View {
    @State private var dateRange: StatsDateRange
    @State private var isShowingCustomRangePicker = false
    @State private var viewModels: [any TrafficCardViewModel] = []

    @Environment(\.context) var context

    init(dateRange: StatsDateRange) {
        self._dateRange = State(initialValue: dateRange)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                ForEach(viewModels, id: \.id) { viewModel in
                    makeItem(for: viewModel)
                }
            }
            .padding(.vertical, Constants.step2)
        }
        .onAppear {
            configureViewModels()
        }
        .onChange(of: dateRange) {
            for viewModel in viewModels {
                viewModel.dateRange = $0
            }
        }
        .background(Constants.Colors.background)
        .toolbar {
            if #available(iOS 26, *) {
                normalModeToolbarContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            if #unavailable(iOS 26) {
                LegacyFloatingDateControl(dateRange: $dateRange)
            }
        }
        .sheet(isPresented: $isShowingCustomRangePicker) {
            CustomDateRangePicker(dateRange: $dateRange)
        }
    }

    @ViewBuilder
    private func makeItem(for viewModel: TrafficCardViewModel) -> some View {
        switch viewModel {
        case let viewModel as ChartCardViewModel:
            ChartCard(viewModel: viewModel)
                .cardStyle()
        case let viewModel as TopListCardViewModel:
            TopListCard(viewModel: viewModel)
                .cardStyle()
        default:
            let _ = assertionFailure("Unsupported type: \(viewModel)")
            EmptyView()
        }
    }

    private func configureViewModels() {
        guard viewModels.isEmpty else {
            return
        }
        viewModels = [
            ChartCardViewModel(
                metrics: context.service.supportedMetrics,
                dateRange: dateRange,
                service: context.service
            ),
            TopListCardViewModel(
                selection: .init(item: .postsAndPages, metric: .views),
                dateRange: dateRange,
                service: context.service
            )
        ]
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
            ForEach(dateRange.availableAdjacentPeriods(in: direction)) { period in
                Button(period.displayText) {
                    dateRange = period.range
                }
            }
        } label: {
            Image(systemName: direction.systemImage)
        } primaryAction: {
            dateRange = dateRange.navigate(direction)
        }
        .disabled(!dateRange.canNavigate(in: direction))
        .tint(.primary)
    }

    // MARK: - Date Picker

    private var datePickerToolbarItem: some View {
        Menu {
            StatsDateRangePickerMenu(selection: $dateRange, isShowingCustomRangePicker: $isShowingCustomRangePicker)
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
            Text(context.formatters.dateRange.string(from: dateRange.dateInterval))
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
    }

    private var comparisonRangeText: String {
        let range = dateRange.effectiveComparisonInterval
        let localizedText = context.formatters.dateRange.string(from: range)
        return localizedText
    }
}

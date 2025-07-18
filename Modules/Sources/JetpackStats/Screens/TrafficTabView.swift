import SwiftUI

struct TrafficTabView: View {
    @State private var dateRange: StatsDateRange
    @State private var isShowingCustomRangePicker = false

    @Environment(\.context) var context

    init(dateRange: StatsDateRange) {
        self._dateRange = State(initialValue: dateRange)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Constants.step3) {
                overviewChart
                postAndPagesList
                authorsList
            }
            .padding(.vertical, Constants.step2)
        }
        .background(Constants.Colors.statsBackground)
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

    // MARK: - Cards

    private var overviewChart: some View {
        ChartCard(
            metrics: SiteMetric.allCases,
            dateRange: dateRange,
            service: context.service
        )
        .cardStyle()
    }

    private var postAndPagesList: some View {
        TopListCard(
            dateRange: dateRange,
            availableDataTypes: TopListItemType.allCases,
            initialDataType: .postsAndPages,
            service: context.service
        )
        .cardStyle()
    }

    private var authorsList: some View {
        TopListCard(
            dateRange: dateRange,
            availableDataTypes: TopListItemType.allCases,
            initialDataType: .authors,
            service: context.service
        )
        .cardStyle()
    }
}

import SwiftUI

struct StatsDateRangeButtons: View {
    @Binding var dateRange: StatsDateRange
    @State private var isShowingCustomRangePicker = false

    var body: some View {
        Group {
            StatsDatePickerToolbarItem(
                dateRange: $dateRange,
                isShowingCustomRangePicker: $isShowingCustomRangePicker
            )
            .modifier(ProminentMenuModifier())
            .popover(isPresented: $isShowingCustomRangePicker) {
                CustomDateRangePicker(dateRange: $dateRange)
                    .frame(idealWidth: 360)
            }
            StatsNavigationButton(dateRange: $dateRange, direction: .backward)
                .modifier(ProminentMenuModifier())
            StatsNavigationButton(dateRange: $dateRange, direction: .forward)
                .modifier(ProminentMenuModifier())
        }

    }
}

struct StatsDatePickerToolbarItem: View {
    @Binding var dateRange: StatsDateRange
    @Binding var isShowingCustomRangePicker: Bool

    @Environment(\.context) var context

    var body: some View {
        Menu {
            StatsDateRangePickerMenu(
                selection: $dateRange,
                isShowingCustomRangePicker: $isShowingCustomRangePicker
            )
        } label: {
            Label(
                context.formatters.dateRange.string(from: dateRange.dateInterval),
                systemImage: "calendar"
            )
        }
        .labelStyle(.titleAndIcon)
        .menuOrder(.fixed)
        .accessibilityLabel(Strings.Accessibility.dateRangeSelected(context.formatters.dateRange.string(from: dateRange.dateInterval)))
        .accessibilityHint(Strings.Accessibility.selectDateRange)
    }
}

struct StatsNavigationButton: View {
    @Binding var dateRange: StatsDateRange
    let direction: Calendar.NavigationDirection

    var body: some View {
        let isDisabled = !dateRange.canNavigate(in: direction)

        Menu {
            ForEach(dateRange.availableAdjacentPeriods(in: direction)) { period in
                Button(period.displayText) {
                    dateRange = period.range
                }
            }
        } label: {
            Image(systemName: direction.systemImage)
                .foregroundStyle(isDisabled ? Color(.tertiaryLabel) : Color.primary)
        } primaryAction: {
            dateRange = dateRange.navigate(direction)
        }
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
        .accessibilityLabel(direction == .forward ? Strings.Accessibility.nextPeriod : Strings.Accessibility.previousPeriod)
        .accessibilityHint(direction == .forward ? Strings.Accessibility.navigateToNextDateRange : Strings.Accessibility.navigateToPreviousDateRange)
    }
}

private struct ProminentMenuModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(Color(.tertiaryLabel))
            .foregroundStyle(.primary)
            .menuStyle(.button)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
    }
}

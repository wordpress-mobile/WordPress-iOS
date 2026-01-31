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
            HStack {
                Image(systemName: "calendar")
                Text(context.formatters.dateRange.string(from: dateRange.dateInterval))
            }
        }
        .menuOrder(.fixed)
        .menuStyle(.button)
        .accessibilityLabel(Strings.Accessibility.dateRangeSelected(context.formatters.dateRange.string(from: dateRange.dateInterval)))
        .accessibilityHint(Strings.Accessibility.selectDateRange)
    }
}

struct StatsNavigationButton: View {
    @Binding var dateRange: StatsDateRange
    let direction: NavigationDirection

    @Environment(\.context) var context

    var body: some View {
        let isDisabled = !dateRange.canNavigate(in: direction)

        Button {
            // Track navigation
            let periodType = dateRange.preset?.analyticsName ?? "custom"
            context.tracker?.send(.dateNavigationButtonTapped, properties: [
                "direction": direction == .forward ? "next" : "previous",
                "current_period_type": periodType
            ])

            dateRange = dateRange.navigate(direction)
        } label: {
            Image(systemName: direction.systemImage)
                .foregroundStyle(isDisabled ? Color(.tertiaryLabel) : Color.primary)
        }
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
        .accessibilityLabel(direction == .forward ? Strings.Accessibility.nextPeriod : Strings.Accessibility.previousPeriod)
        .accessibilityHint(direction == .forward ? Strings.Accessibility.navigateToNextDateRange : Strings.Accessibility.navigateToPreviousDateRange)
    }
}

private struct ProminentMenuModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #unavailable(iOS 26) {
            // Make these stand-out in a plain per-iOS 26 design
            content
                .tint(Color(.tertiaryLabel))
                .foregroundStyle(.primary)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        } else {
            content
        }
    }
}

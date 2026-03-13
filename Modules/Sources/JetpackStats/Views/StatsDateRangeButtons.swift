import SwiftUI

struct StatsDateRangeButtons: View {
    @Binding var dateRange: StatsDateRangeSelection
    @State private var isShowingCustomRangePicker = false

    private var dateRangeBinding: Binding<StatsDateRange> {
        Binding(
            get: { dateRange.range },
            set: { dateRange = StatsDateRangeSelection(range: $0) }
        )
    }

    var body: some View {
        Group {
            StatsDatePickerToolbarItem(
                dateRange: $dateRange,
                isShowingCustomRangePicker: $isShowingCustomRangePicker
            )
            .modifier(ProminentMenuModifier())
            .popover(isPresented: $isShowingCustomRangePicker) {
                CustomDateRangePicker(dateRange: dateRangeBinding)
                    .frame(idealWidth: 360)
            }
            StatsNavigationButton(selection: $dateRange, direction: .backward)
                .modifier(ProminentMenuModifier())
            StatsNavigationButton(selection: $dateRange, direction: .forward)
                .modifier(ProminentMenuModifier())
        }

    }
}

struct StatsDatePickerToolbarItem: View {
    @Binding var dateRange: StatsDateRangeSelection
    @Binding var isShowingCustomRangePicker: Bool

    @Environment(\.context) var context

    private var dateRangeBinding: Binding<StatsDateRange> {
        Binding(
            get: { dateRange.range },
            set: { dateRange = StatsDateRangeSelection(range: $0) }
        )
    }

    var body: some View {
        Menu {
            StatsDateRangePickerMenu(
                selection: dateRangeBinding,
                isShowingCustomRangePicker: $isShowingCustomRangePicker
            )
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(context.formatters.dateRange.string(from: dateRange.effectiveDateRange.dateInterval))
            }
        }
        .menuOrder(.fixed)
        .menuStyle(.button)
        .accessibilityLabel(Strings.Accessibility.dateRangeSelected(context.formatters.dateRange.string(from: dateRange.effectiveDateRange.dateInterval)))
        .accessibilityHint(Strings.Accessibility.selectDateRange)
    }
}

struct StatsNavigationButton: View {
    @Binding var selection: StatsDateRangeSelection
    let direction: NavigationDirection

    @Environment(\.context) var context

    var body: some View {
        let isDisabled = !selection.canNavigate(in: direction)

        Button {
            // Track navigation
            let periodType = selection.range.preset?.analyticsName ?? "custom"
            context.tracker?.send(.dateNavigationButtonTapped, properties: [
                "direction": direction == .forward ? "next" : "previous",
                "current_period_type": periodType
            ])

            selection.navigate(direction)
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

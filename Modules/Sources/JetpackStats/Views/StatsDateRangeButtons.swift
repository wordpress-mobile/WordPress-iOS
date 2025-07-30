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
                    .frame(width: 360)
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
    }
}

struct StatsNavigationButton: View {
    @Binding var dateRange: StatsDateRange
    let direction: Calendar.NavigationDirection
    
    var body: some View {
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

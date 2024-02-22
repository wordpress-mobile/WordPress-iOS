import SwiftUI
import DesignSystem

struct StatsTrafficDatePickerView: View {
    @ObservedObject var viewModel = StatsTrafficDatePickerViewModel()

    var body: some View {
        HStack {
            Menu {
                ForEach([StatsPeriodUnit.day, .week, .month, .year], id: \.self) { period in
                    Button(period.label, action: {
                        viewModel.selectedPeriod = period
                    })
                }
            } label: {
                Text(viewModel.selectedPeriod.label)
                    .style(TextStyle.bodyMedium(.emphasized))
                    .foregroundColor(Color.DS.Foreground.primary)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
                    .foregroundColor(Color.DS.Foreground.secondary)
            }
            .menuStyle(.borderlessButton)
            .padding(.vertical, Length.Padding.single)
            .padding(.horizontal, Length.Padding.double)
            .background(Color.DS.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: Length.Radius.max))
            .overlay(
                RoundedRectangle(cornerRadius: Length.Radius.max)
                    .strokeBorder(.clear, lineWidth: 0)
            )

            Spacer()

            Text(viewModel.formattedCurrentInterval())
                .style(TextStyle.bodyMedium(.emphasized))
                .foregroundColor(Color.DS.Foreground.primary)
                .lineLimit(1)

            Button(action: {
                viewModel.goToPreviousDateInterval()
            }) {
                Image(systemName: "chevron.left")
                    .imageScale(.medium)
                    .foregroundColor(Color.DS.Foreground.secondary)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .padding(.trailing, Length.Padding.single)

            let isNextDisabled = !viewModel.isNextDateIntervalAvailable
            let enabledColor = Color.DS.Foreground.secondary
            let disabledColor = enabledColor.opacity(0.5)

            Button(action: {
                viewModel.goToNextDateInterval()
            }) {
                Image(systemName: "chevron.right")
                    .imageScale(.medium)
                    .foregroundColor(isNextDisabled ? disabledColor : enabledColor)
                    .flipsForRightToLeftLayoutDirection(true)
            }.disabled(isNextDisabled)
        }
    }
}

private extension StatsPeriodUnit {
    var label: String {
        switch self {
        case .day:
            return NSLocalizedString("stats.traffic.day", value: "By day", comment: "The label for the option to show Stats Traffic by day.")
        case .week:
            return NSLocalizedString("stats.traffic.week", value: "By week", comment: "The label for the option to show Stats Traffic by week.")
        case .month:
            return NSLocalizedString("stats.traffic.month", value: "By month", comment: "The label for the option to show Stats Traffic by month.")
        case .year:
            return NSLocalizedString("stats.traffic.year", value: "By year", comment: "The label for the option to show Stats Traffic by year.")
        }
    }
}

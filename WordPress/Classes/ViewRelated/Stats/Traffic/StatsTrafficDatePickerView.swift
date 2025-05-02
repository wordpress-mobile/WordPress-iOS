import SwiftUI
import DesignSystem
import WordPressKit

struct StatsTrafficDatePickerView: View {
    @ObservedObject var viewModel: StatsTrafficDatePickerViewModel

    private let maxDynamicTypeSize: DynamicTypeSize = .xxxLarge

    var body: some View {
        HStack {
            granularityPicker
                .padding(.leading, 16) // Matching grouped table style
            Spacer()
            periodPicker
                .padding(.trailing, 16)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var granularityPicker: some View {
        Menu {
            ForEach([StatsPeriodUnit.day, .week, .month, .year], id: \.self) { period in
                Button(period.label, action: {
                    viewModel.period = period
                })
            }
        } label: {
            HStack {
                Text(viewModel.period.label)
                    .style(TextStyle.bodySmall(.emphasized))
                    .foregroundColor(Color.primary)
                    .dynamicTypeSize(...maxDynamicTypeSize)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
                    .dynamicTypeSize(...maxDynamicTypeSize)
            }
            .padding(.vertical, .DS.Padding.single)
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private var periodPicker: some View {
        HStack(spacing: 8) {
            Text(viewModel.formattedCurrentPeriod())
                .style(TextStyle.bodySmall(.emphasized))
                .foregroundColor(Color.primary)
                .lineLimit(1)
                .dynamicTypeSize(...maxDynamicTypeSize)
                .padding(.trailing, 8)

            let isNextDisabled = !viewModel.isNextPeriodAvailable
            let isPreviousDisabled = !viewModel.isPreviousPeriodAvailable
            let enabledColor = Color.primary
            let disabledColor = Color.secondary.opacity(0.5)

            Button(action: {
                viewModel.goToPreviousPeriod()
            }) {
                Image(systemName: "chevron.left")
                    .imageScale(.small)
                    .foregroundColor(isPreviousDisabled ? disabledColor : enabledColor)
                    .flipsForRightToLeftLayoutDirection(true)
                    .padding(.vertical, .DS.Padding.double)
                    .contentShape(Rectangle())
                    .dynamicTypeSize(...maxDynamicTypeSize)
            }
            .disabled(isPreviousDisabled)
            .padding(.trailing, .DS.Padding.single)

            Button(action: {
                viewModel.goToNextPeriod()
            }) {
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundColor(isNextDisabled ? disabledColor : enabledColor)
                    .flipsForRightToLeftLayoutDirection(true)
                    .padding(.vertical, .DS.Padding.double)
                    .contentShape(Rectangle())
                    .dynamicTypeSize(...maxDynamicTypeSize)
            }
            .disabled(isNextDisabled)
        }
    }
}

private extension StatsPeriodUnit {
    var label: String {
        switch self {
        case .day:
            return NSLocalizedString("stats.traffic.days", value: "Days", comment: "The label for the option to show Stats Traffic chart for Days.")
        case .week:
            return NSLocalizedString("stats.traffic.weeks", value: "Weeks", comment: "The label for the option to show Stats Traffic chart for Weeks.")
        case .month:
            return NSLocalizedString("stats.traffic.months", value: "Months", comment: "The label for the option to show Stats Traffic chart for Months.")
        case .year:
            return NSLocalizedString("stats.traffic.years", value: "Years", comment: "The label for the option to show Stats Traffic chart for Years.")
        }
    }
}

import SwiftUI
import DesignSystem

struct StatsTrafficDatePickerView: View {
    @ObservedObject var viewModel: StatsTrafficDatePickerViewModel

    private let maxDynamicTypeSize: DynamicTypeSize = .xxxLarge

    var body: some View {
        HStack {
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
                        .foregroundColor(Color.DS.Foreground.primary)
                        .dynamicTypeSize(...maxDynamicTypeSize)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(Color.DS.Foreground.secondary)
                        .dynamicTypeSize(...maxDynamicTypeSize)
                }
                .padding(.vertical, Length.Padding.single)
                .padding(.horizontal, Length.Padding.double)
                .background(Color.DS.Background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: Length.Radius.max))
                .overlay(
                    RoundedRectangle(cornerRadius: Length.Radius.max)
                        .strokeBorder(.clear, lineWidth: 0)
                )
                .padding(.vertical, Length.Padding.single)
                .padding(.horizontal, Length.Padding.double)
            }
            .menuStyle(.borderlessButton)

            Spacer()

            Text(viewModel.formattedCurrentPeriod())
                .style(TextStyle.bodySmall(.emphasized))
                .foregroundColor(Color.DS.Foreground.primary)
                .lineLimit(1)
                .dynamicTypeSize(...maxDynamicTypeSize)

            Spacer().frame(width: Length.Padding.split)

            HStack {
                Button(action: {
                    viewModel.goToPreviousPeriod()
                }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.small)
                        .foregroundColor(Color.DS.Foreground.secondary)
                        .flipsForRightToLeftLayoutDirection(true)
                        .padding(.vertical, Length.Padding.double)
                        .contentShape(Rectangle())
                        .dynamicTypeSize(...maxDynamicTypeSize)
                }
                .padding(.trailing, Length.Padding.single)

                let isNextDisabled = !viewModel.isNextPeriodAvailable
                let enabledColor = Color.DS.Foreground.secondary
                let disabledColor = enabledColor.opacity(0.5)

                Button(action: {
                    viewModel.goToNextPeriod()
                }) {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundColor(isNextDisabled ? disabledColor : enabledColor)
                        .flipsForRightToLeftLayoutDirection(true)
                        .padding(.vertical, Length.Padding.double)
                        .contentShape(Rectangle())
                        .dynamicTypeSize(...maxDynamicTypeSize)
                }.disabled(isNextDisabled)
            }.padding(.trailing, Length.Padding.medium)

        }.background(Color.DS.Background.primary)
            .overlay(
                Rectangle()
                    .frame(height: Length.Border.thin)
                    .foregroundColor(Color.DS.Foreground.tertiary),
                alignment: .bottom
            )
            .background(Color.DS.Background.secondary)
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

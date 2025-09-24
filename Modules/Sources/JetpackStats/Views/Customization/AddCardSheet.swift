import SwiftUI

enum AddCardType {
    case chart
    case topList
}

struct AddCardSheet: View {
    let onCardTypeSelected: (AddCardType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Constants.step1) {
            cardTypeSelection
        }

    }

    private var cardTypeSelection: some View {
        VStack(spacing: Constants.step0_5) {
            cardTypeButton(
                title: Strings.AddChart.chartOption,
                subtitle: Strings.AddChart.chartDescription,
                icon: "chart.line.uptrend.xyaxis",
                color: Constants.Colors.blue,
                action: {
                    onCardTypeSelected(.chart)
                    dismiss()
                }
            )

            cardTypeButton(
                title: Strings.AddChart.topListOption,
                subtitle: Strings.AddChart.topListDescription,
                icon: "list.number",
                color: Constants.Colors.purple,
                action: {
                    onCardTypeSelected(.topList)
                    dismiss()
                }
            )
        }
        .padding(Constants.step1)
    }

    private func cardTypeButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Constants.step1) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, Constants.step1)
            .padding(.vertical, Constants.step0_5)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

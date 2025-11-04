import SwiftUI

struct AddCardSheet: View {
    let onCardTypeSelected: (CardType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Constants.step0_5) {
            ForEach(CardType.allCases) { card in
                Button {
                    onCardTypeSelected(card)
                    dismiss()
                } label: {
                    makeLabel(for: card)
                }
            }
        }
        .padding(Constants.step1)
    }

    private func makeLabel(for card: CardType) -> some View {
        HStack(spacing: Constants.step1) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.tint.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: card.systemImage)
                    .font(.body)
                    .foregroundColor(card.tint)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(card.localizedTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.primary)
                Text(card.localizedDescription)
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

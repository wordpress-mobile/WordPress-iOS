import SwiftUI

/// A card with a title and a value stacked vertically
struct VerticalCard: View {
    let title: LocalizedString
    let value: Int
    let largeText: Bool

    private var titleFont: Font {
        largeText ? Appearance.largeTextFont : Appearance.textFont
    }

    private var accessibilityLabel: Text {
        // The colon makes VoiceOver pause between elements
        Text(title) + Text(": ") + Text(value.abbreviatedString())
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(Appearance.titleFont)
                .fontWeight(Appearance.titleFontWeight)
                .foregroundColor(Appearance.titleColor)
                .accessibility(hidden: true)
            StatsValueView(value: value,
                           font: titleFont,
                           fontWeight: .regular,
                           foregroundColor: Appearance.textColor,
                           lineLimit: nil)
                .accessibility(label: accessibilityLabel)

        }
        .flipsForRightToLeftLayoutDirection(true)
    }
}

// MARK: - Appearance
extension VerticalCard {

    private enum Appearance {

        static let titleFont = Font.caption
        static let titleFontWeight = Font.Weight.semibold
        static let titleColor = Color("Blue50")

        static let largeTextFont = Font.largeTitle
        static let textFont = Font.title
        static let textColor = Color(.label)
    }
}

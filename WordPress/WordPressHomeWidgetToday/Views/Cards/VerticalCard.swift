import SwiftUI

/// A card with a title and a value stacked vertically
struct VerticalCard: View {
    let title: LocalizedStringKey
    let value: LocalizedStringKey
    let largeText: Bool

    private var titleFont: Font {
        largeText ? Appearance.largeTextFont : Appearance.textFont
    }

    private var accessibilityLabel: Text {
        // The colon makes VoiceOver pause between elements
        Text(title) + Text(": ") + Text(value)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(Appearance.titleFont)
                .fontWeight(Appearance.titleFontWeight)
                .foregroundColor(Appearance.titleColor)
                .accessibility(hidden: true)
            Text(value)
                .font(titleFont)
                .foregroundColor(Appearance.textColor)
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

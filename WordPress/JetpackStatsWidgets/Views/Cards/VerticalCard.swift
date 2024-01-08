import SwiftUI

/// A card with a title and a value stacked vertically
struct VerticalCard: View {
    let title: LocalizedString
    let value: Int
    let largeText: Bool

    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground: Bool

    private var titleFont: Font {
        largeText ? Appearance.largeTextFont : Appearance.textFont
    }

    private var accessibilityLabel: Text {
        // The colon makes VoiceOver pause between elements
        Text(title) + Text(": ") + Text(value.abbreviatedString())
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showsWidgetContainerBackground {
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
            } else {
                StatsValueView(value: value,
                               font: Appearance.extraLargeTextFont,
                               fontWeight: .heavy,
                               foregroundColor: Appearance.textColor,
                               lineLimit: nil)
                    .accessibility(label: accessibilityLabel)
                Text(title)
                    .font(Appearance.titleFont)
                    .fontWeight(Appearance.titleFontWeight)
                    .foregroundColor(Appearance.titleColor)
                    .accessibility(hidden: true)
            }
        }
    }
}

// MARK: - Appearance
extension VerticalCard {

    private enum Appearance {

        static let titleFont = Font.caption
        static let titleFontWeight = Font.Weight.semibold
        static let titleColor = Color(UIColor.primary)

        static let largeTextFont = Font.largeTitle
        static let extraLargeTextFont = Font.system(size: 48, weight: .bold)
        static let textFont = Font.title
        static let textColor = Color(.label)
    }
}

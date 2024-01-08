import SwiftUI

/// A card with a title and a value stacked vertically shown on LockScreen without background
struct LockScreenVerticalCard: View {
    let title: LocalizedString
    let value: Int

    private var accessibilityLabel: Text {
        // The colon makes VoiceOver pause between elements
        Text(title) + Text(": ") + Text(value.abbreviatedString())
    }

    var body: some View {
        VStack(alignment: .leading) {
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

// MARK: - Appearance
extension LockScreenVerticalCard {
    private enum Appearance {
        static let titleFont = Font.headline
        static let titleFontWeight = Font.Weight.semibold
        static let titleColor = Color(UIColor.label)
        static let extraLargeTextFont = Font.system(size: 48, weight: .bold)
        static let textColor = Color(UIColor.label)
    }
}

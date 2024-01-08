import SwiftUI

/// A card with a title and a string value that is shown on LockScreen without background
struct LockScreenFlexibleCard: View {
    let title: LocalizedString
    let description: LocalizedString
    let lineLimit: Int

    init(title: LocalizedString, description: LocalizedString, lineLimit: Int = 1) {
        self.title = title
        self.description = description
        self.lineLimit = lineLimit
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image("icon-jetpack")
                    .resizable()
                    .frame(width: 14, height: 14)
                Text(description)
                    .font(Appearance.textFont)
                    .fontWeight(Appearance.textFontWeight)
                    .foregroundColor(Appearance.textColor)
                    .lineLimit(lineLimit)
            }
            Text(title)
                .font(Appearance.titleFont)
                .foregroundColor(Appearance.titleColor)
        }
    }
}

// MARK: - Appearance
extension LockScreenFlexibleCard {
    private enum Appearance {
        static let textFont = Font.headline
        static let textFontWeight = Font.Weight.semibold
        static let textColor = Color(.label)

        static let titleFont = Font.subheadline
        static let titleColor = Color(.secondaryLabel)
    }
}

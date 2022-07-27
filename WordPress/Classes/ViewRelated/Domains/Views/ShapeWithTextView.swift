import SwiftUI

/// A rounded rectangle shape with a white title and a primary background color
struct ShapeWithTextView: View {
    var title: String

    var body: some View {
        Text(title)
    }

    func largeRoundedRectangle(textColor: Color = .white,
                               backgroundColor: Color = Appearance.largeRoundedRectangleDefaultTextColor) -> some View {
        body
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.all, Appearance.largeRoundedRectangleTextPadding)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Appearance.largeRoundedRectangleCornerRadius,
                                        style: .continuous))
    }

    func smallRoundedRectangle(textColor: Color = Appearance.smallRoundedRectangleDefaultTextColor,
                               backgroundColor: Color = Appearance.smallRoundedRectangleDefaultBackgroundColor) -> some View {
        body
            .font(.system(size: Appearance.smallRoundedRectangleFontSize))
            .padding(Appearance.smallRoundedRectangleInsets)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Appearance.smallRoundedRectangleCornerRadius,
                                        style: .continuous))

    }

    private enum Appearance {
        // large rounded rectangle
        static let largeRoundedRectangleCornerRadius: CGFloat = 8.0
        static let largeRoundedRectangleTextPadding: CGFloat = 12.0
        static let largeRoundedRectangleDefaultTextColor = Color(UIColor.muriel(color: .primary))
        // small rounded rectangle
        static let smallRoundedRectangleCornerRadius: CGFloat = 4.0
        static let smallRoundedRectangleInsets = EdgeInsets(top: 4.0, leading: 8.0, bottom: 4.0, trailing: 8.0)
        static let smallRoundedRectangleDefaultBackgroundColor = Color(UIColor.muriel(name: .green, .shade5))
        static let smallRoundedRectangleDefaultTextColor = Color(UIColor.muriel(name: .green, .shade100))
        static let smallRoundedRectangleFontSize: CGFloat = 14.0
    }
}

import SwiftUI

/// General purpose container view with a rounded rectangle background
struct RoundRectangleView<Content: View>: View {
    private let content: Content

    private let rectangleFillColor = Color(UIColor(light: .white, dark: .gray(.shade90)))
    private let cornerRadius: CGFloat = 4
    private let shadowRadius: CGFloat = 4
    private let shadowColor = Color.gray.opacity(0.4)

    private var alignment: Alignment

    init(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .foregroundColor(rectangleFillColor)
                .shadow(color: shadowColor, radius: shadowRadius)
            content
        }
    }
}

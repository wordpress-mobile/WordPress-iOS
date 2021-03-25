import SwiftUI

/// General purpose container view with a rounded rectangle background
struct RoundRectangleView<Content: View>: View {
    private let content: Content

    private let rectangleFillColor = Color(UIColor(light: .white, dark: .gray(.shade90)))
    private let cornerRadius: CGFloat = 4

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .foregroundColor(rectangleFillColor)
            content
        }
    }
}

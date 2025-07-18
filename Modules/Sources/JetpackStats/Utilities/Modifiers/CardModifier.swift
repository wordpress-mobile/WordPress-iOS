import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(UIColor(light: .systemBackground, dark: .secondarySystemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.opaqueSeparator), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, Constants.step1)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

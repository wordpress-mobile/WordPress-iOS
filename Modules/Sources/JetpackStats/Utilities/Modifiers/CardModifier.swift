import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Constants.Colors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color(.opaqueSeparator), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

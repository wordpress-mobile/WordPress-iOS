import SwiftUI

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44.0, maxHeight: 44.0)
            .background(Color(.primary))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
}

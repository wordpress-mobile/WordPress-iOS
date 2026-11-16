import SwiftUI

struct ScrollOffsetModifier: ViewModifier {
    @Binding var isScrolled: Bool

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometry in
                return (geometry.contentOffset.y - 20) > -geometry.contentInsets.top
            } action: { _, newValue in
                if isScrolled != newValue {
                    isScrolled = newValue
                }
            }
    }
}

extension View {
    func trackScrollOffset(isScrolled: Binding<Bool>) -> some View {
        modifier(ScrollOffsetModifier(isScrolled: isScrolled))
    }
}

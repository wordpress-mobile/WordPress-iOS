import SwiftUI

@available(iOS 18.0, *)
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
    @ViewBuilder
    func trackScrollOffset(isScrolling: Binding<Bool>) -> some View {
        if #available(iOS 18.0, *) {
            modifier(ScrollOffsetModifier(isScrolled: isScrolling))
        } else {
            self
        }
    }
}

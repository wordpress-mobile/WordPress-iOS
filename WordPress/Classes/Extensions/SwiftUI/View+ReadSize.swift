import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct SizeModifier: ViewModifier {
    let size: (CGSize) -> Void

    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }

    func body(content: Content) -> some View {
        content.background(
            sizeView
                .onPreferenceChange(SizePreferenceKey.self, perform: { value in
                    size(value)
                })
        )
    }
}

extension View {
    func readSize(_ size: @escaping (CGSize) -> Void) -> some View {
        modifier(SizeModifier(size: size))
    }
}

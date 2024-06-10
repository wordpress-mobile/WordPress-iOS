import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct SizeModifier: ViewModifier {
    let includeSafeArea: Bool
    let sizeChanged: (CGSize) -> Void

    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: SizePreferenceKey.self,
                value: size(from: geometry)
            )
        }
    }

    private func size(from proxy: GeometryProxy) -> CGSize {
        var size = proxy.size
        if includeSafeArea {
            size.height += proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            size.width += proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
        }
        return size
    }

    func body(content: Content) -> some View {
        content.background(
            sizeView
                .onPreferenceChange(SizePreferenceKey.self, perform: { value in
                    sizeChanged(value)
                })
        )
    }
}

extension View {
    func readSize(includeSafeArea: Bool = false, sizeChanged: @escaping (CGSize) -> Void) -> some View {
        modifier(SizeModifier(includeSafeArea: includeSafeArea, sizeChanged: sizeChanged))
    }
}

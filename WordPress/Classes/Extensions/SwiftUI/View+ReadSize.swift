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
    /// A view extension that allows reading the size of a view and responding to size changes.
    /// - Parameters:
    ///   - includeSafeArea: A Boolean value that indicates whether to include the safe area insets in the size calculation.
    ///   - sizeChanged: A callback function that is called with the new size whenever it changes.
    /// - Returns: A view that reads its size and passes it to the `sizeChanged` callback.
    func readSize(includeSafeArea: Bool = false, sizeChanged: @escaping (CGSize) -> Void) -> some View {
        modifier(SizeModifier(includeSafeArea: includeSafeArea, sizeChanged: sizeChanged))
    }
}

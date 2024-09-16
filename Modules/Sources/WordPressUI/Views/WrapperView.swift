import SwiftUI

public struct WrapperView <WrappedView: View>: View {

    var wrappedView: () -> WrappedView

    public init(@ViewBuilder wrappedView: @escaping () -> WrappedView) {
        self.wrappedView = wrappedView
    }

    public var body: some View {
        wrappedView()
    }
}

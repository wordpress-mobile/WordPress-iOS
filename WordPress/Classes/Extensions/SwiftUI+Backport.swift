import SwiftUI

struct Backport<T: View> {
    let view: T
}

extension View {
    var backport: Backport<Self> { Backport(view: self) }
}

extension Backport {
    @ViewBuilder
    func refreshable(action: @Sendable @escaping () async -> Void) -> some View {
        if #available(iOS 15, *) {
            view.refreshable(action: action)
        } else {
            view
        }
    }
}

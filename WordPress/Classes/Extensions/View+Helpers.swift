import SwiftUI

extension View {
    func apply<T>(_ closure: (Self) -> T) -> T {
        closure(self)
    }

    @ViewBuilder
    func listSectionCompactSpacing() -> some View {
        if #available(iOS 17, *) {
            listSectionSpacing(.compact)
        } else {
            self
        }
    }
}

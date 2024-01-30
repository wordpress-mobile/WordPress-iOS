import SwiftUI

extension View {
    func apply<T>(_ closure: (Self) -> T) -> T {
        closure(self)
    }
}

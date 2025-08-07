import SwiftUI

struct ChartSelectionModifier: ViewModifier {
    @Binding var selection: Date?

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.chartXSelection(value: $selection)
        } else {
            content
        }
    }
}

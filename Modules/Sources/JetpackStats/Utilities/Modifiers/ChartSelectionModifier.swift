import SwiftUI

struct ChartSelectionModifier: ViewModifier {
    @Binding var selection: Date?

    func body(content: Content) -> some View {
        content.chartXSelection(value: $selection)
    }
}

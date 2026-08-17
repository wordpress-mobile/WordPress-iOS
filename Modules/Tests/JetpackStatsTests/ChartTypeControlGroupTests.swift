import SwiftUI
import Testing
@testable import JetpackStats

@MainActor
struct ChartTypeControlGroupTests {
    @Test("Selecting a chart type updates the selection")
    func selectingChartTypeUpdatesSelection() {
        var selection = ChartType.line
        let controlGroup = ChartTypeControlGroup(
            selection: Binding(
                get: { selection },
                set: { selection = $0 }
            )
        )

        controlGroup.selectionBinding(for: .columns).wrappedValue = true

        #expect(selection == .columns)
    }

    @Test("Deselecting the active chart type keeps it selected")
    func deselectingChartTypeKeepsSelection() {
        var selection = ChartType.line
        let controlGroup = ChartTypeControlGroup(
            selection: Binding(
                get: { selection },
                set: { selection = $0 }
            )
        )

        controlGroup.selectionBinding(for: .line).wrappedValue = false

        #expect(selection == .line)
    }
}

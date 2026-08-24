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

    @Test("Reflects the active type and never clears the selection")
    func deselectingChartTypeKeepsSelection() {
        var selection = ChartType.line
        let controlGroup = ChartTypeControlGroup(
            selection: Binding(
                get: { selection },
                set: { selection = $0 }
            )
        )

        #expect(controlGroup.selectionBinding(for: .line).wrappedValue == true)
        #expect(controlGroup.selectionBinding(for: .columns).wrappedValue == false)

        // Deselecting is a no-op: `set(false)` must never change the selection.
        controlGroup.selectionBinding(for: .columns).wrappedValue = false
        #expect(selection == .line)
    }
}

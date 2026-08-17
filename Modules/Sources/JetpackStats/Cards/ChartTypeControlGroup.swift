import SwiftUI

struct ChartTypeControlGroup: View {
    @Binding var selection: ChartType

    var body: some View {
        ControlGroup {
            ForEach(ChartType.allCases) { type in
                Toggle(isOn: selectionBinding(for: type)) {
                    Label(type.localizedTitle, systemImage: type.systemImage)
                }
                .toggleStyle(.button)
            }
        }
    }

    func selectionBinding(for type: ChartType) -> Binding<Bool> {
        Binding(
            get: { selection == type },
            set: { isSelected in
                if isSelected {
                    selection = type
                }
            }
        )
    }
}

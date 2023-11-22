import SwiftUI

struct DSButtonGallery: View {
    var body: some View {
        List {
            Group {
                DSButton(title: "Primary", style: .primary) { () }
                DSButton(title: "Secondary", style: .secondary) { () }
                DSButton(title: "Tertiary", style: .tertiary) { () }
                DSButton(title: "Primary", style: .primary) { () }
                    .disabled(true)
                DSButton(title: "Secondary", style: .secondary) { () }
                    .disabled(true)
                DSButton(title: "Tertiary", style: .tertiary) { () }
                    .disabled(true)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .navigationTitle("DSButton")
    }
}

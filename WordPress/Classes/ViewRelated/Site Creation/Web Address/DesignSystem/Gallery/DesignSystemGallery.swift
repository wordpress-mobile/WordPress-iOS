import SwiftUI

struct DesignSystemGallery: View {
    private let rows = [
        "Color",
        "Spacing"
    ]

    var body: some View {
        List {
            NavigationLink {
                ColorGallery()
            } label: {
                Text("Color")
            }

            NavigationLink {
                SpacingGallery()
            } label: {
                Text("Spacing")
            }
        }
        .navigationTitle("Design System")
    }
}

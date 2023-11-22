import SwiftUI

struct DesignSystemGallery: View {
    var body: some View {
        List {
            NavigationLink("Foundation", destination: foundationList)
            NavigationLink("Components", destination: componentsList)
        }
        .navigationTitle("Design System")
    }

    private var foundationList: some View {
        List {
            NavigationLink("Colors", destination: ColorGallery())
            NavigationLink("Fonts", destination: FontGallery())
            NavigationLink("Lengths", destination: LengthGallery())
            NavigationLink("Icons", destination: IconGallery())
        }
        .navigationTitle("Foundation")
    }

    private var componentsList: some View {
        List {
            NavigationLink("DSButton", destination: DSButtonGallery())
        }
        .navigationTitle("Components")
    }
}

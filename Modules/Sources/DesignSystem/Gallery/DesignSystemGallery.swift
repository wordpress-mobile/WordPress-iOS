import SwiftUI

public struct DesignSystemGallery: View {
    public var body: some View {
        List {
            NavigationLink("Foundation", destination: foundationList)
            NavigationLink("Components", destination: componentsList)
        }
        .navigationTitle("Design System")
    }

    public init() { }

    private var foundationList: some View {
        List {
            NavigationLink("Colors", destination: ColorGallery())
            NavigationLink("Fonts", destination: FontGallery())
            NavigationLink("Lengths", destination: LengthGallery())
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

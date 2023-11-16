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
//            NavigationLink("Lengths", destination: LengthGallery())
        }
        .navigationTitle("Foundation")
    }

    private var componentsList: some View {
        List {
            NavigationLink("PrimaryButton", destination: PrimaryButtonGallery())
        }
        .navigationTitle("Components")
    }
}

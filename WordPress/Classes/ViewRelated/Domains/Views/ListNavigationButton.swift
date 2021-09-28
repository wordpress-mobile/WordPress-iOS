import SwiftUI

/// A generic button that can be used to add a custom navigation action in a `List`
struct ListNavigationButton<Destination: View, Appearance: View>: View {
    private var destination: () -> Destination
    private var appearance: () -> Appearance

    @State private var isActive: Bool = false

    var body: some View {
        ZStack {
            NavigationLink(destination: self.destination(), isActive: self.$isActive) {
                EmptyView()
            }
            .hidden()

            Button(action: {
                self.isActive.toggle()
            }) {
                self.appearance()
            }
        }
        .buttonStyle(.plain)
    }
}

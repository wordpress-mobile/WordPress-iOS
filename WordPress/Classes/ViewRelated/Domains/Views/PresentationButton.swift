import SwiftUI

struct PresentationButton<Destination: View, Appearance: View>: View {
    var destination: () -> Destination
    var appearance: () -> Appearance

    @State private var showingSheet = false

    var body: some View {
        Button(action: {
            showingSheet.toggle()
        }) {
            self.appearance()
        }
        .sheet(isPresented: $showingSheet) {
            destination()
        }
    }
}

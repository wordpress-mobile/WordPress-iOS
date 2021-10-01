import SwiftUI

struct PresentationButton<Appearance: View>: View {
    @Binding var isShowingDestination: Bool
    var appearance: () -> Appearance

    var body: some View {
        Button(action: {
            isShowingDestination = true
        }) {
            self.appearance()
        }
    }
}

import SwiftUI

struct ContactSupportView: View {

    // TODO: Remove this once delegation to present ZenDesk done
    @State private var alertPresented = false

    var body: some View {
        VStack(spacing: 8) {
            Text("Can't find what you're looking for?").italic()
            Button {
                self.alertPresented.toggle()
            } label: {
                Text("Contact Support")
            }
            .alert(isPresented: $alertPresented) {
                Alert(
                    title: Text("TODO"),
                    message: Text("This should load the Zendesk flow"),
                    dismissButton: .default(Text("Dismiss"))
                )
            }
        }
    }
}

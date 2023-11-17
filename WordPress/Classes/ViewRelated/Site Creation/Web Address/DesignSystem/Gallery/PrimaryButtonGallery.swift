import SwiftUI

struct PrimaryButtonGallery: View {
    var body: some View {
        List {
            Group {
                PrimaryButton(title: "Active") {
                    ()
                }

                PrimaryButton(title: "Disabled") {
                    ()
                }
                .disabled(true)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Primary Button")
    }
}

import SwiftUI

struct PrimaryButtonGallery: View {
    var body: some View {
        List {
            Group {
                PrimaryButton(title: "PrimaryButton S1") {
                    print("Primary Button Tapped.")
                }

                PrimaryButton(title: "PrimaryButton S2") {
                    print("Primary Button Tapped.")
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Primary Button")
    }
}

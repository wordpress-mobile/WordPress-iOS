import SwiftUI

struct FontGallery: View {
    var body: some View {
        List {
            Section("Heading") {
                Text("Heading1")
                    .style(.heading1)
                Text("Heading2")
                    .style(.heading2)
                Text("Heading3")
                    .style(.heading3)
                Text("Heading4")
                    .style(.heading4)
            }

            Section("Body") {
                Text("Body Small Regular")
                    .style(.bodySmall(.regular))
                Text("Body Medium Regular")
                    .style(.bodyMedium(.regular))
                Text("Body Large Regular")
                    .style(.bodyLarge(.regular))
                Text("Body Small Emphasized")
                    .style(.bodySmall(.emphasized))
                Text("Body Medium Emphasized")
                    .style(.bodyMedium(.emphasized))
                Text("Body Large Emphasized")
                    .style(.bodyLarge(.emphasized))
            }

            Section("Miscellaneous") {
                Text("Footnote")
                    .style(.footnote)
                Text("Caption")
                    .style(.caption)
            }
        }
        .navigationTitle("Fonts")
    }
}

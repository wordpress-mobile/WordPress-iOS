import SwiftUI

struct DSButtonGallery: View {
    var body: some View {
        List {
            Section("Large") {
                DSButton(title: "Primary", style: .init(emphasis: .primary, size: .large)) { () }
                DSButton(title: "Secondary", style: .init(emphasis: .secondary, size: .large)) { () }
                DSButton(title: "Tertiary", style: .init(emphasis: .tertiary, size: .large)) { () }
                DSButton(title: "Primary Disabled", style: .init(emphasis: .primary, size: .large)) { () }
                    .disabled(true)
                DSButton(title: "Secondary Disabled", style: .init(emphasis: .secondary, size: .large)) { () }
                    .disabled(true)
                DSButton(title: "Tertiary Disabled", style: .init(emphasis: .tertiary, size: .large)) { () }
                    .disabled(true)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: Length.Padding.split, leading: 0, bottom: Length.Padding.split, trailing: 0))

            Section("Medium") {
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: Length.Padding.medium) {
                        DSButton(title: "Primary", style: .init(emphasis: .primary, size: .medium)) { () }
                        DSButton(title: "Secondary", style: .init(emphasis: .secondary, size: .medium)) { () }
                        DSButton(title: "Tertiary", style: .init(emphasis: .tertiary, size: .medium)) { () }
                        DSButton(title: "Primary Disabled", style: .init(emphasis: .primary, size: .medium)) { () }
                            .disabled(true)
                        DSButton(title: "Secondary Disabled", style: .init(emphasis: .secondary, size: .medium)) { () }
                            .disabled(true)
                        DSButton(title: "Tertiary Disabled", style: .init(emphasis: .tertiary, size: .medium)) { () }
                            .disabled(true)
                    }
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section("Small") {
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: Length.Padding.medium) {
                        DSButton(title: "Primary", style: .init(emphasis: .primary, size: .small)) { () }
                        DSButton(title: "Secondary", style: .init(emphasis: .secondary, size: .small)) { () }
                        DSButton(title: "Tertiary", style: .init(emphasis: .tertiary, size: .small)) { () }
                        DSButton(title: "Primary Disabled", style: .init(emphasis: .primary, size: .small)) { () }
                            .disabled(true)
                        DSButton(title: "Secondary Disabled", style: .init(emphasis: .secondary, size: .small)) { () }
                            .disabled(true)
                        DSButton(title: "Tertiary Disabled", style: .init(emphasis: .tertiary, size: .small)) { () }
                            .disabled(true)
                    }
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .navigationTitle("DSButton")
    }
}

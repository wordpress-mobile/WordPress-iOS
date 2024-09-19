import SwiftUI

struct DSButtonGallery: View {
    var body: some View {
        List {
            ForEach(DSButtonStyle.Size.allCases, id: \.title) { size in
                Section(size.title) {
                    HStack {
                        Spacer()
                        VStack(spacing: .DS.Padding.medium) {
                            ForEach(DSButtonStyle.Emphasis.allCases, id: \.title) { emphasis in
                                DSButton(
                                    title: emphasis.title,
                                    iconName: .checkmark,
                                    style: .init(
                                        emphasis: emphasis,
                                        size: size,
                                        isJetpack: true
                                    )
                                ) {()}
                            }
                            ForEach(DSButtonStyle.Emphasis.allCases, id: \.title) { emphasis in
                                DSButton(
                                    title: emphasis.title + " Disabled",
                                    style: .init(
                                        emphasis: emphasis,
                                        size: size,
                                        isJetpack: true
                                    )
                                ) {()}
                                    .disabled(true)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: .DS.Padding.split, leading: 0, bottom: .DS.Padding.split, trailing: 0))
            }
            .navigationTitle("DSButton")
        }.tint(.blue)
    }
}

private extension DSButtonStyle.Size {
    var title: String {
        switch self {
        case .large:
            return "Large"
        case .medium:
            return "Medium"
        case .small:
            return "Small"
        }
    }
}

private extension DSButtonStyle.Emphasis {
    var title: String {
        switch self {
        case .primary:
            return "Primary"
        case .secondary:
            return "Secondary"
        case .tertiary:
            return "Tertiary"
        }
    }
}

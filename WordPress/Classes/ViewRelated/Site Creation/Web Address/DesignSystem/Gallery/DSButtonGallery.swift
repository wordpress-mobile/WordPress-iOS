import SwiftUI

struct DSButtonGallery: View {
    var body: some View {
        List {
            ForEach(DSButtonStyle.Size.allCases, id: \.title) { size in
                Section(size.title) {
                    ForEach(DSButtonStyle.Emphasis.allCases, id: \.title) { emphasis in
                        DSButton(title: emphasis.title, style: .init(emphasis: emphasis, size: size)) { () }
                    }

                    ForEach(DSButtonStyle.Emphasis.allCases, id: \.title) { emphasis in
                        DSButton(title: emphasis.title, style: .init(emphasis: emphasis, size: size)) { () }
                            .disabled(true)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: Length.Padding.split, leading: 0, bottom: Length.Padding.split, trailing: 0))
            }
            .navigationTitle("DSButton")
        }
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

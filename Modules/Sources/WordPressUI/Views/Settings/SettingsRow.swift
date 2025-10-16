import SwiftUI

public struct SettingsRow<Content: View>: View {
    let title: String
    let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        HStack {
            Text(title)
                .layoutPriority(1)
            Spacer()
            content
                .font(.callout)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
        .lineLimit(1)
    }
}

public extension SettingsRow where Content == Text {
    init(_ title: String, value: String) {
        self.init(title) {
            Text(value)
        }
    }
}

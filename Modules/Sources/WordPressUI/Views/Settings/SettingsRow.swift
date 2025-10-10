import SwiftUI

public struct SettingsRow: View {
    let title: String
    let value: String

    public init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        HStack {
            Text(title)
                .layoutPriority(1)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
        .lineLimit(1)
    }
}

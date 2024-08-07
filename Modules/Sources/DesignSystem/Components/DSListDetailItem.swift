import SwiftUI

public struct DSListDetailItem: View {

    let title: String
    let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }.contextMenu(ContextMenu(menuItems: {
            Button("Copy", systemImage: "doc.on.doc.fill") {
                UIPasteboard.general.string = value
            }
        }))
    }
}

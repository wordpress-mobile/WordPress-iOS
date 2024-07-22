import SwiftUI

public struct DSEditableListDetailItemView: View {
    public let title: String

    @Binding
    var value: String

    public init(title: String, value: Binding<String>) {
        self.title = title
        self._value = value
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            TextField("Device Name", text: $value)
        }.contextMenu(ContextMenu(menuItems: {
            Button("Copy", systemImage: "doc.on.doc.fill") {
                UIPasteboard.general.string = value
            }
        }))
    }
}

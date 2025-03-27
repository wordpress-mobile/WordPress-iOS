import SwiftUI
import DesignSystem
import Network

struct ApplicationTokenItemView: View {
    @State private var isConfirmingDeletion: Bool = false

    private let token: ApplicationTokenItem

    init(token: ApplicationTokenItem) {
        self.token = token
    }

    var body: some View {
        Form {
            Section {
                detailItem(title: Self.name, value: token.name)
            }

            Section(Self.security) {
                detailItem(title: Self.creationDate, value: token.createdAt.formatted())

                if let lastUsed = token.lastUsed {
                    detailItem(title: Self.lastUsed, value: lastUsed.formatted())
                }

                if let lastIpAddress = token.lastIpAddress {
                    detailItem(title: Self.lastUsedIp, value: lastIpAddress)
                }
            }
        }
        .navigationTitle(token.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .contextMenu {
            Button("Copy", systemImage: "doc.on.doc.fill") {
                UIPasteboard.general.string = value
            }
        }
    }
}

// MARK: - Localization

private extension ApplicationTokenItemView {
    static var name: String { NSLocalizedString("applicationPassword.item.name", value: "Name", comment: "Title of row for displaying an application password name") }

    static var security: String { NSLocalizedString("applicationPassword.item.section.security", value: "Security", comment: "Title of section for displaying application password details") }

    static var creationDate: String { NSLocalizedString("applicationPassword.item.creationDate", value: "Creation Date", comment: "Title of row for displaying an application password's creation date") }

    static var lastUsed: String { NSLocalizedString("applicationPassword.item.lastUsed", value: "Last Used", comment: "Title of row for displaying an application password's last used date") }

    static var lastUsedIp: String { NSLocalizedString("applicationPassword.item.lastUsed", value: "Last IP Address", comment: "Title of row for displaying an application password's last used IP address") }
}

// MARK: - SwiftUI Preview

extension ApplicationTokenItem {
    static let bobToken = ApplicationTokenItem(name: "Bob's iPad Mini", uuid: UUID(), appId: "1234", createdAt: .now, lastUsed: .now.advanced(by: -10_000), lastIpAddress: IPv4Address.any.debugDescription)

    static let aliceToken = ApplicationTokenItem(name: "Alice's super fast and tiny tablet with keyboard", uuid: UUID(), appId: "1234", createdAt: .now, lastUsed: nil, lastIpAddress: nil)
}

extension [ApplicationTokenItem] {
    static let testTokens: [ApplicationTokenItem] = [
        .bobToken,
        .aliceToken
    ]
}

#Preview {
    NavigationView {
        ApplicationTokenItemView(token: .aliceToken)
    }
}

#Preview {
    NavigationView {
        ApplicationTokenItemView(token: .bobToken)
    }
}

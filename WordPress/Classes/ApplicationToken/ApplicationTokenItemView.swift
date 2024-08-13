import SwiftUI
import DesignSystem

struct ApplicationTokenItemView: View {
    @State private var isConfirmingDeletion: Bool = false

    private let token: ApplicationTokenItem

    init(token: ApplicationTokenItem) {
        self.token = token
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text(Self.name)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(token.name)
                }
                .contextMenu(ContextMenu(menuItems: {
                    Button(SharedStrings.Button.copy, systemImage: "doc.on.doc.fill") {
                        UIPasteboard.general.string = token.name
                    }
                }))
            }

            Section(Self.security) {
                DSListDetailItem(title: Self.creationDate, value: token.createdAt.formatted())

                if let lastUsed = token.lastUsed {
                    DSListDetailItem(title: Self.lastUsed, value: lastUsed.formatted())
                }

                if let lastIpAddress = token.lastIpAddress {
                    DSListDetailItem(title: Self.lastUsedIp, value: lastIpAddress)
                }
            }
        }
        .navigationTitle(token.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Localization

private extension ApplicationTokenItemView {
    static var name: String { NSLocalizedString("application-password.item.name", value: "Name", comment: "Title of row for displaying an application password name") }

    static var security: String { NSLocalizedString("application-password.item.section.security", value: "Security", comment: "Title of section for displaying application password details") }

    static var creationDate: String { NSLocalizedString("application-password.item.creatationDate", value: "Creation Date", comment: "Title of row for displaying an application password's creation date") }

    static var lastUsed: String { NSLocalizedString("application-password.item.lastUsed", value: "Last Used", comment: "Title of row for displaying an application password's last used date") }

    static var lastUsedIp: String { NSLocalizedString("application-password.item.lastUsed", value: "Last IP Address", comment: "Title of row for displaying an application password's last used IP address") }
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

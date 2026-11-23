import SwiftUI
import DesignSystem
import Network
import WordPressUI

struct ApplicationTokenItemView: View {
    @State private var isConfirmingDeletion: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var deletionError: Error?
    @ObservedObject var viewModel: ApplicationTokenListViewModel
    private let initialToken: ApplicationTokenItem

    private var token: ApplicationTokenItem {
        viewModel.applicationTokens.first { $0.uuid == initialToken.uuid } ?? initialToken
    }

    init(token: ApplicationTokenItem, viewModel: ApplicationTokenListViewModel) {
        self.initialToken = token
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Section {
                detailItem(title: Self.name, value: token.name)
            }

            Section {
                detailItem(title: Self.creationDate, value: token.createdAt.formatted())

                if let lastUsed = token.lastUsed {
                    detailItem(title: Self.lastUsed, value: lastUsed.formatted())
                }

                if let lastIpAddress = token.lastIpAddress {
                    detailItem(title: Self.lastUsedIp, value: lastIpAddress)
                }
            } header: {
                Text(Self.security)
            } footer: {
                if token.isCurrent {
                    HStack(alignment: .firstTextBaseline) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)

                        Text(Self.currentlyInUse)
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    isConfirmingDeletion = true
                } label: {
                    HStack {
                        Text(Self.revokeTitle)
                        Spacer()
                        if viewModel.deletingTokenID == token.uuid { ProgressView() }
                    }
                }
                .disabled(!token.canDelete || viewModel.deletingTokenID != nil)

                if !token.isCurrent && !token.canDelete {
                    Button(SharedStrings.Button.retry) {
                        Task { await viewModel.fetchTokens() }
                    }
                    .disabled(viewModel.isLoadingData || viewModel.deletingTokenID != nil)
                }
            } footer: {
                if !token.canDelete {
                    Text(token.deletionBlocker.localizedDescription)
                    if let error = viewModel.errorMessage { Text(error) }
                }
            }
        }
        .alert(Self.revokeTitle, isPresented: $isConfirmingDeletion) {
            Button(Self.revokeButton, role: .destructive) {
                Task {
                    do {
                        if try await viewModel.deleteToken(token) { dismiss() }
                    } catch {
                        deletionError = error
                    }
                }
            }
            Button(SharedStrings.Button.cancel, role: .cancel) {}
        } message: {
            Text(String.localizedStringWithFormat(Self.revokeMessage, token.name))
        }
        .alert(
            Self.revokeErrorTitle,
            isPresented: Binding(
                get: { deletionError != nil },
                set: { if !$0 { deletionError = nil } }
            )
        ) {
            Button(SharedStrings.Button.ok, role: .cancel) {}
        } message: {
            Text(deletionError?.localizedDescription ?? "")
        }
        .onChange(of: viewModel.credentialRevision) { _, _ in
            isConfirmingDeletion = false
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
    static var revokeButton: String {
        NSLocalizedString(
            "applicationPassword.revoke.button",
            value: "Revoke",
            comment: "Confirmation button for revoking an application password"
        )
    }

    static var revokeTitle: String {
        NSLocalizedString(
            "applicationPassword.revoke.title",
            value: "Revoke Application Password",
            comment: "Button and confirmation title for revoking an application password"
        )
    }

    static var revokeMessage: String {
        NSLocalizedString(
            "applicationPassword.revoke.message",
            value: "Revoke “%1$@”? Apps using this password will lose access to your site.",
            comment: "Revocation confirmation. %1$@ is the application password name."
        )
    }

    static var revokeErrorTitle: String {
        NSLocalizedString(
            "applicationPassword.revoke.errorTitle",
            value: "Could Not Revoke Application Password",
            comment: "Title of application password revocation error"
        )
    }

    static var name: String {
        NSLocalizedString(
            "applicationPassword.item.name",
            value: "Name",
            comment: "Title of row for displaying an application password name"
        )
    }

    static var security: String {
        NSLocalizedString(
            "applicationPassword.item.section.security",
            value: "Security",
            comment: "Title of section for displaying application password details"
        )
    }

    static var creationDate: String {
        NSLocalizedString(
            "applicationPassword.item.creationDate",
            value: "Creation Date",
            comment: "Title of row for displaying an application password's creation date"
        )
    }

    static var lastUsed: String {
        NSLocalizedString(
            "applicationPassword.item.lastUsed",
            value: "Last Used",
            comment: "Title of row for displaying an application password's last used date"
        )
    }

    static var lastUsedIp: String {
        NSLocalizedString(
            "applicationPassword.item.lastUsedIp",
            value: "Last IP Address",
            comment: "Title of row for displaying an application password's last used IP address"
        )
    }

    static var currentlyInUse: String {
        NSLocalizedString(
            "applicationPassword.item.currentlyInUse",
            value: "This application password is currently being used by the app.",
            comment:
                "Footer message indicating that this application password is currently active and being used by the app"
        )
    }
}

// MARK: - SwiftUI Preview

extension ApplicationTokenItem {
    static let bobToken = ApplicationTokenItem(
        name: "Bob's iPad Mini",
        uuid: UUID(),
        appId: "1234",
        createdAt: .now,
        lastUsed: .now.advanced(by: -10_000),
        lastIpAddress: IPv4Address.any.debugDescription
    )

    static let aliceToken = ApplicationTokenItem(
        name: "Alice's super fast and tiny tablet with keyboard",
        uuid: UUID(),
        appId: "1234",
        createdAt: .now,
        lastUsed: nil,
        lastIpAddress: nil
    )
}

extension [ApplicationTokenItem] {
    static let testTokens: [ApplicationTokenItem] = [
        .bobToken,
        .aliceToken
    ]
}

#Preview {
    NavigationView {
        ApplicationTokenItemView(
            token: .aliceToken,
            viewModel: ApplicationTokenListViewModel(dataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
        )
    }
}

#Preview {
    NavigationView {
        ApplicationTokenItemView(
            token: .bobToken,
            viewModel: ApplicationTokenListViewModel(dataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
        )
    }
}

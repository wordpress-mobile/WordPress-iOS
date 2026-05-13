import SwiftUI

public struct PostSocialSharingDetailView: View {
    @ObservedObject private var connections: SiteSocialConnectionsService
    @Binding private var draft: PostSocialSharingDraft
    private let onAddConnection: (() -> Void)?

    public init(
        connections: SiteSocialConnectionsService,
        draft: Binding<PostSocialSharingDraft>,
        onAddConnection: (() -> Void)? = nil
    ) {
        self.connections = connections
        self._draft = draft
        self.onAddConnection = onAddConnection
    }

    public var body: some View {
        Form {
            togglesSection
            customMessageSection
        }
        .navigationTitle(Strings.PostSection.header)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            _ = try? await connections.loadConnections()
        }
    }

    @ViewBuilder
    private var togglesSection: some View {
        switch connections.connections {
        case .loading:
            Section {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        case .loaded(let list) where list.isEmpty:
            Section {
                Text(Strings.PostSection.emptyCaption)
                    .foregroundStyle(.secondary)
                connectRow
            }
        case .loaded(let list):
            Section {
                ForEach(list) { connection in
                    Toggle(isOn: bindingForToggle(connection: connection)) {
                        SocialConnectionRow(connection: connection)
                    }
                }
                connectRow
            } footer: {
                Text(Strings.PostSection.togglesFooter)
            }
        case .failed(let error):
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.errorDescription ?? "")
                        .foregroundStyle(.red)
                    Button(Strings.PostSection.retry) {
                        Task { _ = try? await connections.loadConnections(force: true) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var connectRow: some View {
        if let onAddConnection {
            Button {
                onAddConnection()
            } label: {
                Text(Strings.ManageConnections.connectNewAccount)
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var customMessageSection: some View {
        Section {
            TextField(
                Strings.PostSection.customMessagePlaceholder,
                text: Binding(
                    get: { draft.customMessage ?? "" },
                    set: { draft.customMessage = $0.isEmpty ? nil : $0 }
                ),
                axis: .vertical
            )
            .lineLimit(2...5)
        } header: {
            Text(Strings.PostSection.customMessageLabel)
        } footer: {
            Text(Strings.PostSection.customMessageFooter)
        }
    }

    private func bindingForToggle(connection: SocialConnection) -> Binding<Bool> {
        Binding(
            get: { draft.isEnabled(connectionID: connection.id) },
            set: { isEnabled in
                draft.setEnabled(
                    isEnabled,
                    for: connection,
                    availableConnections: connections.connections.value ?? []
                )
            }
        )
    }
}

extension PostSocialSharingDraft {
    /// Short summary for the "Share to Social" post settings entry row.
    /// Returns `nil` when the row should render without a trailing value —
    /// i.e. the list is empty (covers both "not loaded yet" and "no
    /// connections") or all/none of the connections are enabled.
    public func summary(for connections: [SocialConnection]) -> String? {
        guard !connections.isEmpty else { return nil }
        let enabledCount = connections.filter { isEnabled(connectionID: $0.id) }.count
        if enabledCount == 0 || enabledCount == connections.count {
            return nil
        }
        return String.localizedStringWithFormat(
            Strings.PostSection.summaryFormat,
            enabledCount,
            connections.count
        )
    }
}

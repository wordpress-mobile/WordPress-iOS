import SwiftUI

public struct ManageSocialConnectionsView: View {
    @ObservedObject private var connections: SiteSocialConnectionsService
    private let onAddConnection: () -> Void

    public init(
        connections: SiteSocialConnectionsService,
        onAddConnection: @escaping () -> Void
    ) {
        self.connections = connections
        self.onAddConnection = onAddConnection
    }

    public var body: some View {
        Form {
            connectionsSection
            errorSection
        }
        .navigationTitle(Strings.ManageConnections.navigationTitle)
        .task {
            await connections.loadConnections(force: false)
        }
        .refreshable {
            await connections.loadConnections(force: true)
        }
    }

    @ViewBuilder
    private var connectionsSection: some View {
        Section {
            connectionsRows
            connectRow
        } header: {
            Text(Strings.ManageConnections.connectedHeader)
        } footer: {
            Text(Strings.ManageConnections.connectedFooter)
        }
    }

    @ViewBuilder
    private var connectionsRows: some View {
        switch connections.connections {
        case .loading:
            loadingRow
        case .loaded(let list):
            ForEach(list) { connection in
                NavigationLink {
                    SocialConnectionDetailView(
                        connection: connection,
                        connections: connections
                    )
                } label: {
                    SocialConnectionRow(connection: connection)
                }
            }
        case .failed:
            EmptyView()
        }
    }

    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }

    private var connectRow: some View {
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

    @ViewBuilder
    private var errorSection: some View {
        if let error = connections.connections.error {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.errorDescription ?? "")
                        .foregroundStyle(.red)
                    Button(Strings.ManageConnections.retry) {
                        Task { await connections.loadConnections(force: true) }
                    }
                }
            }
        }
    }

}

#if DEBUG
#Preview("Loading") {
    NavigationStack {
        ManageSocialConnectionsView(
            connections: SiteSocialConnectionsService.preview(),
            onAddConnection: {}
        )
    }
}

#Preview("Populated") {
    NavigationStack {
        ManageSocialConnectionsView(
            connections: SiteSocialConnectionsService.preview(
                connections: [
                    SocialConnection(
                        id: "1",
                        externalID: "@tony",
                        serviceName: "mastodon",
                        serviceLabel: "Mastodon",
                        displayName: "Tony",
                        externalHandle: "@tony@mastodon.social",
                        profileLink: nil,
                        profilePictureURL: nil,
                        isShared: false,
                        status: .ok
                    )
                ]
            ),
            onAddConnection: {}
        )
    }
}
#endif

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
            _ = try? await connections.loadConnections(force: false)
        }
        .refreshable {
            _ = try? await connections.loadConnections(force: true)
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
                        Task { _ = try? await connections.loadConnections(force: true) }
                    }
                }
            }
        }
    }
}

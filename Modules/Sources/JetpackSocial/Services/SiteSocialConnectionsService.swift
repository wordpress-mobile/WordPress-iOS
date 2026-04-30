import Foundation
import Logging
import WordPressAPI

public final class SiteSocialConnectionsService: ObservableObject, @unchecked Sendable {
    @MainActor @Published public private(set) var connections: SocialConnectionsState = .loading
    @MainActor @Published public private(set) var services: SocialServicesState = .loading

    private let client: WPComApiClient
    private let siteId: Int64

    /// Only sites hosted on or connected to WP.com are supported. The
    /// factory is responsible for not constructing this service when the
    /// blog has no WP.com account.
    public init(client: WPComApiClient, siteId: Int64) {
        self.client = client
        self.siteId = siteId
    }

    // MARK: - Reads

    public func loadConnections(force: Bool = false) async {
        if !force, await isConnectionsLoaded() {
            return
        }
        await setConnections(.loading)
        do {
            let wireResponse = try await client.publicize.listConnections(wpComSiteId: UInt64(siteId))
            let mapped = wireResponse.data.map(SocialConnection.init(from:))
            await setConnections(.loaded(mapped))
        } catch {
            let wrapped = wrap(error)
            log.error("loadConnections failed: \(wrapped)")
            await setConnections(.failed(wrapped))
        }
    }

    public func loadServices(force: Bool = false) async {
        if !force, await isServicesLoaded() {
            return
        }
        await setServices(.loading)
        do {
            let wireResponse = try await client.publicize.listServices(wpComSiteId: UInt64(siteId))
            let mapped = wireResponse.data.map(SocialService.init(from:))
            await setServices(.loaded(mapped))
        } catch {
            let wrapped = wrap(error)
            log.error("loadServices failed: \(wrapped)")
            await setServices(.failed(wrapped))
        }
    }

    public func fetchKeyringConnections() async throws(SocialSharingError) -> [SocialKeyringConnection] {
        do {
            let wireResponse = try await client.meConnections.list()
            return wireResponse.data.connections.map(SocialKeyringConnection.init(from:))
        } catch {
            let wrapped = wrap(error)
            log.error("fetchKeyringConnections failed: \(wrapped)")
            throw wrapped
        }
    }

    /// Snapshot of the currently loaded connection IDs. Returns `[]` if
    /// `connections` has not been loaded yet.
    @MainActor
    public func currentConnectionIDs() -> [String] {
        connections.value?.map(\.id) ?? []
    }

    // MARK: - Mutations

    @discardableResult
    public func createConnection(
        keyringID: Int64,
        externalUserID: String? = nil,
        shared: Bool = false
    ) async throws(SocialSharingError) -> SocialConnection {
        do {
            let params = CreatePublicizeConnectionParams(
                keyringConnectionId: keyringID,
                externalUserId: externalUserID,
                shared: shared
            )
            let wireResponse = try await client.publicize.createConnection(
                wpComSiteId: UInt64(siteId),
                params: params
            )
            let connection = SocialConnection(from: wireResponse.data)
            await appendOrReplace(connection)
            return connection
        } catch {
            let wrapped = wrap(error)
            log.error("createConnection keyringID=\(keyringID) failed: \(wrapped)")
            throw wrapped
        }
    }

    public func deleteConnection(id: String) async throws(SocialSharingError) {
        do {
            _ = try await client.publicize.deleteConnection(
                wpComSiteId: UInt64(siteId),
                publicizeConnectionId: id
            )
            await remove(connectionWithID: id)
        } catch {
            let wrapped = wrap(error)
            log.error("deleteConnection id=\(id) failed: \(wrapped)")
            throw wrapped
        }
    }

    @discardableResult
    public func updateConnection(
        id: String,
        shared: Bool
    ) async throws(SocialSharingError) -> SocialConnection {
        // Optimistically reflect the change in the @Published state before
        // the network round-trip so SwiftUI can render immediately. Capture
        // the pre-change connection for rollback on failure.
        let rollback = await findConnection(id: id)
        if let rollback, rollback.isShared != shared {
            var optimistic = rollback
            optimistic.isShared = shared
            await appendOrReplace(optimistic)
        }

        do {
            let params = UpdatePublicizeConnectionParams(shared: shared)
            let wireResponse = try await client.publicize.updateConnection(
                wpComSiteId: UInt64(siteId),
                publicizeConnectionId: id,
                params: params
            )
            let connection = SocialConnection(from: wireResponse.data)
            await appendOrReplace(connection)
            return connection
        } catch {
            if let rollback {
                await appendOrReplace(rollback)
            }
            let wrapped = wrap(error)
            log.error("updateConnection id=\(id) failed: \(wrapped)")
            throw wrapped
        }
    }

    // MARK: - MainActor-isolated state mutation

    @MainActor
    private func setConnections(_ value: SocialConnectionsState) {
        connections = value
    }

    @MainActor
    private func isConnectionsLoaded() -> Bool {
        if case .loaded = connections { return true }
        return false
    }

    @MainActor
    private func setServices(_ value: SocialServicesState) {
        services = value
    }

    @MainActor
    private func isServicesLoaded() -> Bool {
        if case .loaded = services { return true }
        return false
    }

    @MainActor
    private func appendOrReplace(_ connection: SocialConnection) {
        var current = connections.value ?? []
        if let idx = current.firstIndex(where: { $0.id == connection.id }) {
            current[idx] = connection
        } else {
            current.append(connection)
        }
        connections = .loaded(current)
    }

    @MainActor
    private func findConnection(id: String) -> SocialConnection? {
        connections.value?.first(where: { $0.id == id })
    }

    @MainActor
    private func remove(connectionWithID id: String) {
        guard var current = connections.value else { return }
        current.removeAll { $0.id == id }
        connections = .loaded(current)
    }

    private func wrap(_ error: Error) -> SocialSharingError {
        if let already = error as? SocialSharingError {
            return already
        }
        return .network(error)
    }

    #if DEBUG
    @MainActor
    internal func _seedForPreview(connections: [SocialConnection]) {
        self.connections = connections.isEmpty ? .loading : .loaded(connections)
    }
    #endif
}

private let log: Logger = Logger(label: "org.wordpress.jetpack-social")

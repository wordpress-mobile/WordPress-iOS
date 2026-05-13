import Foundation
import Logging
import WordPressAPI

@MainActor
public final class SiteSocialConnectionsService: ObservableObject {
    @Published public private(set) var connections: SocialConnectionsState = .loading
    @Published public private(set) var services: SocialServicesState = .loading
    @Published public private(set) var canMarkAsShared: Bool

    private let client: WPComApiClient
    private let siteId: Int64

    /// In-flight load tasks, used to coalesce concurrent callers onto a
    /// single network request. Cleared by each task before it resolves.
    private var loadConnectionsTask: Task<Result<[SocialConnection], SocialSharingError>, Never>?
    private var loadServicesTask: Task<Void, Never>?

    /// Per-connection correlation token, refreshed at the start of every
    /// `updateConnection` call. The post-network state mutation is applied
    /// only when the captured token still matches the current value, so a
    /// late-arriving response from a superseded tap is dropped instead of
    /// clobbering a newer one.
    private var updateTokens: [String: UUID] = [:]

    /// Only sites hosted on or connected to WP.com are supported. The
    /// factory is responsible for not constructing this service when the
    /// blog has no WP.com account.
    public init(client: WPComApiClient, siteId: Int64, canMarkAsShared: Bool) {
        self.client = client
        self.siteId = siteId
        self.canMarkAsShared = canMarkAsShared
    }

    public func updatePermissions(canMarkAsShared: Bool) {
        self.canMarkAsShared = canMarkAsShared
    }

    // MARK: - Reads

    @discardableResult
    public func loadConnections(force: Bool = false) async throws(SocialSharingError) -> [SocialConnection] {
        if !force, case .loaded(let connections) = connections {
            return connections
        }
        if let inFlight = loadConnectionsTask {
            return try await inFlight.socialConnectionValue
        }
        let task = Task<Result<[SocialConnection], SocialSharingError>, Never> { [weak self] in
            guard let self else {
                // This is defensive plumbing, not a user-facing edge case:
                // the service was released before the coalesced load task ran.
                let error = NSError(domain: "org.wordpress.jetpack-social", code: 1)
                return .failure(.unknown(error))
            }
            do throws(SocialSharingError) {
                return .success(try await self.runLoadConnections())
            } catch {
                return .failure(error)
            }
        }
        loadConnectionsTask = task
        return try await task.socialConnectionValue
    }

    private func runLoadConnections() async throws(SocialSharingError) -> [SocialConnection] {
        defer { loadConnectionsTask = nil }
        connections = .loading
        do {
            let wireResponse = try await client.publicize.listConnections(wpComSiteId: UInt64(siteId))
            let mapped = wireResponse.data.map(SocialConnection.init(from:))
            connections = .loaded(mapped)
            return mapped
        } catch {
            let wrapped = wrap(error)
            log.error("loadConnections failed: \(wrapped)")
            connections = .failed(wrapped)
            throw wrapped
        }
    }

    public func loadServices(force: Bool = false) async {
        if !force, case .loaded = services {
            return
        }
        if let inFlight = loadServicesTask {
            await inFlight.value
            return
        }
        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.runLoadServices()
        }
        loadServicesTask = task
        await task.value
    }

    private func runLoadServices() async {
        defer { loadServicesTask = nil }
        services = .loading
        do {
            let wireResponse = try await client.publicize.listServices(wpComSiteId: UInt64(siteId))
            let mapped = wireResponse.data.map(SocialService.init(from:))
            services = .loaded(mapped)
        } catch {
            let wrapped = wrap(error)
            log.error("loadServices failed: \(wrapped)")
            services = .failed(wrapped)
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

    // MARK: - Mutations

    @discardableResult
    public func createConnection(
        keyringID: Int64,
        externalUserID: String? = nil,
        shared: Bool? = nil
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
            appendOrReplace(connection)
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
            remove(connectionWithID: id)
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
        let token = UUID()
        updateTokens[id] = token

        // Optimistically reflect the change in the @Published state before
        // the network round-trip so SwiftUI can render immediately. Capture
        // the pre-change connection for rollback on failure.
        let rollback = findConnection(id: id)
        if let rollback, rollback.isShared != shared {
            var optimistic = rollback
            optimistic.isShared = shared
            appendOrReplace(optimistic)
        }

        do {
            let params = UpdatePublicizeConnectionParams(shared: shared)
            let wireResponse = try await client.publicize.updateConnection(
                wpComSiteId: UInt64(siteId),
                publicizeConnectionId: id,
                params: params
            )
            let connection = SocialConnection(from: wireResponse.data)
            if updateTokens[id] == token {
                appendOrReplace(connection)
            }
            return connection
        } catch {
            let wrapped = wrap(error)
            log.error("updateConnection id=\(id) failed: \(wrapped)")
            if updateTokens[id] == token, let rollback {
                appendOrReplace(rollback)
            }
            throw wrapped
        }
    }

    // MARK: - State mutation helpers

    private func appendOrReplace(_ connection: SocialConnection) {
        var current = connections.value ?? []
        if let idx = current.firstIndex(where: { $0.id == connection.id }) {
            current[idx] = connection
        } else {
            current.append(connection)
        }
        connections = .loaded(current)
    }

    private func findConnection(id: String) -> SocialConnection? {
        connections.value?.first(where: { $0.id == id })
    }

    private func remove(connectionWithID id: String) {
        guard var current = connections.value else { return }
        current.removeAll { $0.id == id }
        connections = .loaded(current)
    }

    nonisolated private func wrap(_ error: Error) -> SocialSharingError {
        if let already = error as? SocialSharingError {
            return already
        }
        return .network(error)
    }
}

private let log = Logger(label: "org.wordpress.jetpack-social")

private extension Task where Success == Result<[SocialConnection], SocialSharingError>, Failure == Never {
    var socialConnectionValue: [SocialConnection] {
        get async throws(SocialSharingError) {
            switch await value {
            case .success(let connections):
                return connections
            case .failure(let error):
                throw error
            }
        }
    }
}

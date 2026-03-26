import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressData
import WordPressKit
import WordPressShared

/// Syncs publicize connections and services from the wordpress-rs publicize
/// endpoints, replacing the legacy `SharingSyncService` and
/// `SharingService.syncPublicizeServicesForBlog`.
@objc class JetpackPublicizeService: NSObject {

    private let coreDataStack: CoreDataStackSwift
    private let wpcomClient: WordPressDotComClient

    init(coreDataStack: CoreDataStackSwift, wpcomClient: WordPressDotComClient) {
        self.coreDataStack = coreDataStack
        self.wpcomClient = wpcomClient
    }

    /// Convenience initializer for Obj-C callers.
    @objc convenience init(coreDataStack: ContextManager) {
        self.init(coreDataStack: coreDataStack, wpcomClient: WordPressDotComClient())
    }

    /// Fetches publicize connections from the remote and merges them into
    /// Core Data, deleting any that no longer exist on the server.
    func syncConnections(for blogID: TaggedManagedObjectID<Blog>) async throws {
        let siteID: UInt64 = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogID)
            guard let dotComID = blog.dotComID?.uint64Value else {
                throw JetpackPublicizeServiceError.missingSiteID
            }
            return dotComID
        }

        let response = try await wpcomClient.api.publicize.listConnections(
            wpComSiteId: siteID
        )

        let currentUserID: Int64 = await coreDataStack.performQuery { context in
            guard let blog = try? context.existingObject(with: blogID),
                  let accountID = blog.account?.userID else {
                return 0
            }
            return accountID.int64Value
        }

        // Only keep connections that are shared, global, or owned by the current user.
        let authorizedConnections = response.data.filter {
            $0.shared || $0.global || $0.wpcomUserId == currentUserID
        }

        try await mergeConnections(authorizedConnections, blogID: blogID)
    }

    /// Fetches available publicize services from the remote and merges them
    /// into Core Data, deleting any that no longer exist on the server.
    func syncServices(for blogID: TaggedManagedObjectID<Blog>) async throws {
        let siteID: UInt64 = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogID)
            guard let dotComID = blog.dotComID?.uint64Value else {
                throw JetpackPublicizeServiceError.missingSiteID
            }
            return dotComID
        }

        let response = try await wpcomClient.api.publicize.listServices(wpComSiteId: siteID)
        try await mergeServices(response.data)
    }

    /// Fetches the current user's keyring connections. Returns in-memory
    /// objects — nothing is saved to Core Data.
    func fetchKeyringConnections() async throws -> [KeyringConnection] {
        let response = try await wpcomClient.api.meConnections.list()
        return response.data.connections.map { Self.mapKeyringConnection(from: $0) }
    }

    /// Creates a new publicize connection using a keyring connection.
    func createConnection(
        for blogID: TaggedManagedObjectID<Blog>,
        keyringConnectionId: Int64,
        externalUserId: String?
    ) async throws -> TaggedManagedObjectID<PublicizeConnection> {
        let siteID: UInt64 = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogID)
            guard let dotComID = blog.dotComID?.uint64Value else {
                throw JetpackPublicizeServiceError.missingSiteID
            }
            return dotComID
        }

        let params = CreatePublicizeConnectionParams(
            keyringConnectionId: keyringConnectionId,
            externalUserId: externalUserId,
            shared: nil
        )
        let response = try await wpcomClient.api.publicize.createConnection(
            wpComSiteId: siteID,
            params: params
        )

        let serviceName = response.data.serviceName
        let objectID: TaggedManagedObjectID<PublicizeConnection> = try await coreDataStack.performAndSave { context in
            let blog = try context.existingObject(with: blogID)
            let connection = Self.findOrCreateConnection(
                connectionID: response.data.connectionId,
                in: context
            )
            Self.update(connection, from: response.data)
            connection.blog = blog
            try context.obtainPermanentIDs(for: [connection])
            return TaggedManagedObjectID(connection)
        }

        let properties = ["service": serviceName]
        WPAppAnalytics.track(.sharingPublicizeConnected, properties: properties, blogID: NSNumber(value: siteID))

        return objectID
    }

    /// Updates the shared status of a publicize connection.
    /// Uses optimistic update — reverts on failure.
    func updateConnectionShared(
        for blogID: TaggedManagedObjectID<Blog>,
        connectionId: String,
        shared: Bool
    ) async throws {
        let (siteID, oldValue, service) = try await coreDataStack.performAndSave { context -> (UInt64, Bool, String) in
            let blog = try context.existingObject(with: blogID)
            guard let dotComID = blog.dotComID?.uint64Value else {
                throw JetpackPublicizeServiceError.missingSiteID
            }
            let connection = Self.findOrCreateConnection(connectionID: connectionId, in: context)
            let oldValue = connection.shared
            connection.shared = shared
            return (dotComID, oldValue, connection.service)
        }

        guard oldValue != shared else { return }

        do {
            let params = UpdatePublicizeConnectionParams(
                externalUserId: nil,
                shared: shared
            )
            let response = try await wpcomClient.api.publicize.updateConnection(
                wpComSiteId: siteID,
                publicizeConnectionId: PublicizeConnectionId(connectionId),
                params: params
            )

            try await coreDataStack.performAndSave { context in
                let blog = try context.existingObject(with: blogID)
                let connection = Self.findOrCreateConnection(
                    connectionID: response.data.connectionId,
                    in: context
                )
                Self.update(connection, from: response.data)
                connection.blog = blog
            }

            let properties = [
                "service": service,
                "is_site_wide": NSNumber(value: shared).stringValue
            ]
            WPAppAnalytics.track(.sharingPublicizeConnectionAvailableToAllChanged, properties: properties, blogID: NSNumber(value: siteID))
        } catch {
            // Revert optimistic update
            try? await coreDataStack.performAndSave { context in
                let connection = Self.findOrCreateConnection(connectionID: connectionId, in: context)
                connection.shared = oldValue
            }
            throw error
        }
    }

    /// Updates the external user ID of a publicize connection.
    func updateConnectionExternalId(
        for blogID: TaggedManagedObjectID<Blog>,
        connectionId: String,
        externalId: String
    ) async throws {
        let siteID: UInt64 = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogID)
            guard let dotComID = blog.dotComID?.uint64Value else {
                throw JetpackPublicizeServiceError.missingSiteID
            }
            return dotComID
        }

        let params = UpdatePublicizeConnectionParams(
            externalUserId: externalId,
            shared: nil
        )
        let response = try await wpcomClient.api.publicize.updateConnection(
            wpComSiteId: siteID,
            publicizeConnectionId: PublicizeConnectionId(connectionId),
            params: params
        )

        try await coreDataStack.performAndSave { context in
            let blog = try context.existingObject(with: blogID)
            let connection = Self.findOrCreateConnection(
                connectionID: response.data.connectionId,
                in: context
            )
            Self.update(connection, from: response.data)
            connection.blog = blog
        }
    }

    /// Deletes a publicize connection. Uses optimistic delete — removes from
    /// Core Data immediately, then calls the API.
    func deleteConnection(
        for blogID: TaggedManagedObjectID<Blog>,
        connectionId: String
    ) async throws {
        let (siteID, service) = try await coreDataStack.performAndSave { context -> (UInt64, String) in
            let blog = try context.existingObject(with: blogID)
            guard let dotComID = blog.dotComID?.uint64Value else {
                throw JetpackPublicizeServiceError.missingSiteID
            }
            let connection = Self.findOrCreateConnection(connectionID: connectionId, in: context)
            let service = connection.service
            context.delete(connection)
            return (dotComID, service)
        }

        do {
            _ = try await wpcomClient.api.publicize.deleteConnection(
                wpComSiteId: siteID,
                publicizeConnectionId: PublicizeConnectionId(connectionId)
            )
        } catch {
            // FIXME: The error handling here may need adjustment. The wordpress-rs API may not
            // surface not_found errors in the same way as the legacy WordPressComRestApi.
            let nsError = error as NSError
            if let errorCode = nsError.userInfo["WordPressComRestApiErrorCodeKey"] as? String,
               errorCode == "not_found" {
                // Already disconnected — treat as success
            } else {
                throw error
            }
        }

        let properties = ["service": service]
        WPAppAnalytics.track(.sharingPublicizeDisconnected, properties: properties, blogID: NSNumber(value: siteID))
    }

    // MARK: - Obj-C Bridge Methods

    @objc func syncConnections(
        for blog: Blog,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            do {
                try await syncConnections(for: blogID)
                success?()
            } catch {
                failure?(error as NSError)
            }
        }
    }

    @objc func syncServices(
        for blog: Blog,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            do {
                try await syncServices(for: blogID)
                success?()
            } catch {
                failure?(error as NSError)
            }
        }
    }

    @objc func fetchKeyringConnections(
        for blog: Blog,
        success: (([KeyringConnection]) -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        Task { @MainActor in
            do {
                let connections = try await fetchKeyringConnections()
                success?(connections)
            } catch {
                failure?(error as NSError)
            }
        }
    }

    @objc func createConnection(
        for blog: Blog,
        keyring: KeyringConnection,
        externalUserID: String?,
        success: ((PublicizeConnection) -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            do {
                let objectID = try await createConnection(
                    for: blogID,
                    keyringConnectionId: keyring.keyringID.int64Value,
                    externalUserId: externalUserID
                )
                let connection = try self.coreDataStack.mainContext.existingObject(with: objectID)
                success?(connection)
            } catch {
                failure?(error as NSError)
            }
        }
    }

    @objc func updateShared(
        for blog: Blog,
        shared: Bool,
        forPublicizeConnection pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        let connectionId = String(pubConn.connectionID.intValue)
        Task { @MainActor in
            do {
                try await updateConnectionShared(
                    for: blogID,
                    connectionId: connectionId,
                    shared: shared
                )
                success?()
            } catch {
                failure?(error as NSError)
            }
        }
    }

    @objc func updateExternalID(
        _ externalID: String,
        for blog: Blog,
        forPublicizeConnection pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        let connectionId = String(pubConn.connectionID.intValue)
        Task { @MainActor in
            do {
                try await updateConnectionExternalId(
                    for: blogID,
                    connectionId: connectionId,
                    externalId: externalID
                )
                success?()
            } catch {
                failure?(error as NSError)
            }
        }
    }

    @objc func deleteConnection(
        for blog: Blog,
        pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        let connectionId = String(pubConn.connectionID.intValue)
        Task { @MainActor in
            do {
                try await deleteConnection(for: blogID, connectionId: connectionId)
                success?()
            } catch {
                failure?(error as NSError)
            }
        }
    }

    // MARK: - Private Merge Methods

    /// Merges remote connections into Core Data for a given blog.
    private func mergeConnections(
        _ remoteConnections: [PublicizeConnectionResponse],
        blogID: TaggedManagedObjectID<Blog>
    ) async throws {
        try await coreDataStack.performAndSave { context in
            let blog: Blog
            do {
                blog = try context.existingObject(with: blogID)
            } catch {
                Loggers.app.error("Error fetching Blog: \(error)")
                return
            }

            let currentConnections = Self.fetchExistingConnections(for: blog, in: context)

            let connectionsToKeep = remoteConnections.map { remote -> PublicizeConnection in
                let connection = Self.findOrCreateConnection(
                    connectionID: remote.connectionId,
                    in: context
                )
                Self.update(connection, from: remote)
                connection.blog = blog
                return connection
            }

            for connection in currentConnections {
                if !connectionsToKeep.contains(connection) {
                    context.delete(connection)
                }
            }
        }
    }

    /// Merges remote services into Core Data. This is global (not blog-scoped),
    /// matching the behavior of the legacy `SharingService`.
    private func mergeServices(_ remoteServices: [PublicizeServiceResponse]) async throws {
        try await coreDataStack.performAndSave { context in
            let currentServices = (try? PublicizeService.allPublicizeServices(in: context)) ?? []

            let servicesToKeep = remoteServices.map { remote -> PublicizeService in
                Self.createOrUpdateService(from: remote, in: context)
            }

            for service in currentServices {
                if !servicesToKeep.contains(service) {
                    context.delete(service)
                }
            }
        }
    }

    // MARK: - Connection Helpers

    private static func fetchExistingConnections(
        for blog: Blog,
        in context: NSManagedObjectContext
    ) -> [PublicizeConnection] {
        let request = NSFetchRequest<NSFetchRequestResult>(
            entityName: PublicizeConnection.classNameWithoutNamespaces()
        )
        request.predicate = NSPredicate(format: "blog = %@", blog)

        do {
            return try context.fetch(request) as! [PublicizeConnection]
        } catch {
            Loggers.app.error("Error fetching Publicize Connections: \(error.localizedDescription)")
            return []
        }
    }

    private static func findOrCreateConnection(
        connectionID: String,
        in context: NSManagedObjectContext
    ) -> PublicizeConnection {
        if let connectionIDNumber = Int(connectionID) {
            let request = NSFetchRequest<PublicizeConnection>(
                entityName: PublicizeConnection.classNameWithoutNamespaces()
            )
            request.predicate = NSPredicate(
                format: "connectionID = %@",
                NSNumber(value: connectionIDNumber)
            )
            if let existing = try? context.fetch(request).first {
                return existing
            }
        }

        return NSEntityDescription.insertNewObject(
            forEntityName: PublicizeConnection.classNameWithoutNamespaces(),
            into: context
        ) as! PublicizeConnection
    }

    private static func update(
        _ connection: PublicizeConnection,
        from remote: PublicizeConnectionResponse
    ) {
        if let idValue = Int(remote.connectionId) {
            connection.connectionID = NSNumber(value: idValue)
        }
        connection.externalDisplay = remote.displayName
        connection.service = remote.serviceName
        connection.externalProfilePicture = remote.profilePicture
        connection.externalProfileURL = remote.profileLink
        connection.status = remote.status ?? "ok"
        connection.shared = remote.shared || remote.global
        connection.externalID = remote.externalId
        connection.externalName = remote.username

        // TODO: Unmapped remote fields: id, externalHandle, serviceLabel,
        // profileDisplayName, wpcomUserId
        // TODO: Unmapped Core Data fields: keyringConnectionID,
        // keyringConnectionUserID, label, refreshURL
    }

    // MARK: - Service Helpers

    private static func createOrUpdateService(
        from remote: PublicizeServiceResponse,
        in context: NSManagedObjectContext
    ) -> PublicizeService {
        var service = try? PublicizeService.lookupPublicizeServiceNamed(remote.id, in: context)
        if service == nil {
            service = NSEntityDescription.insertNewObject(
                forEntityName: PublicizeService.entityName(),
                into: context
            ) as? PublicizeService
        }

        service?.serviceID = remote.id
        service?.detail = remote.description
        service?.label = remote.label
        service?.status = remote.status.isEmpty ? PublicizeService.defaultStatus : remote.status
        service?.multipleExternalUserIDSupport = remote.supports.additionalUsers
        service?.externalUsersOnly = remote.supports.additionalUsersOnly
        service?.connectURL = remote.url

        // TODO: Unmapped Core Data field: icon (not in v2 response)

        return service!
    }

    // MARK: - Keyring Mapping

    private static func mapKeyringConnection(
        from response: KeyringConnectionResponse
    ) -> KeyringConnection {
        let conn = KeyringConnection()
        conn.keyringID = NSNumber(value: response.id)
        conn.userID = NSNumber(value: response.userId)
        conn.service = response.service
        conn.label = response.label ?? ""
        conn.externalID = response.externalId
        conn.externalName = response.externalName
        conn.externalDisplay = response.externalDisplay
        conn.externalProfilePicture = response.externalProfilePicture ?? ""
        conn.status = response.status
        conn.refreshURL = response.refreshUrl
        conn.additionalExternalUsers = response.additionalExternalUsers.map { user in
            let extUser = KeyringConnectionExternalUser()
            extUser.externalID = user.externalId
            extUser.externalName = user.externalName
            extUser.externalProfilePicture = user.externalProfilePicture ?? ""
            extUser.externalCategory = user.externalCategory ?? ""
            return extUser
        }
        return conn
    }

    // MARK: - Error

    enum JetpackPublicizeServiceError: Error {
        case missingSiteID
    }
}

import Foundation

extension PublicizeConnection {

    /// Composes a new `PublicizeConnection`, or updates an existing one, with
    /// data represented by the passed `RemotePublicizeConnection`.
    ///
    /// - Parameter remoteConnection: The remote connection representing the publicize connection.
    ///
    /// - Returns: A `PublicizeConnection`.
    ///
    static func createOrReplace(from remoteConnection: RemotePublicizeConnection, in context: NSManagedObjectContext) -> PublicizeConnection {
        let pubConnection = findPublicizeConnection(byID: remoteConnection.connectionID, in: context)
            ?? NSEntityDescription.insertNewObject(forEntityName: PublicizeConnection.classNameWithoutNamespaces(),
                into: context) as! PublicizeConnection

        pubConnection.connectionID = remoteConnection.connectionID
        pubConnection.dateExpires = remoteConnection.dateExpires
        pubConnection.dateIssued = remoteConnection.dateIssued
        pubConnection.externalDisplay = remoteConnection.externalDisplay
        pubConnection.externalFollowerCount = remoteConnection.externalFollowerCount
        pubConnection.externalID = remoteConnection.externalID
        pubConnection.externalName = remoteConnection.externalName
        pubConnection.externalProfilePicture = remoteConnection.externalProfilePicture
        pubConnection.externalProfileURL = remoteConnection.externalProfileURL
        pubConnection.keyringConnectionID = remoteConnection.keyringConnectionID
        pubConnection.keyringConnectionUserID = remoteConnection.keyringConnectionUserID
        pubConnection.label = remoteConnection.label
        pubConnection.refreshURL = remoteConnection.refreshURL
        pubConnection.service = remoteConnection.service
        pubConnection.shared = remoteConnection.shared
        pubConnection.status = remoteConnection.status
        pubConnection.siteID = remoteConnection.siteID
        pubConnection.userID = remoteConnection.userID

        return pubConnection
    }

    /// Finds a cached `PublicizeConnection` by its `connectionID`
    ///
    /// - Parameter connectionID: The ID of the `PublicizeConnection`.
    ///
    /// - Returns: The requested `PublicizeConnection` or nil.
    ///
    private static func findPublicizeConnection(byID connectionID: NSNumber, in context: NSManagedObjectContext) -> PublicizeConnection? {
        let request = NSFetchRequest<PublicizeConnection>(entityName: PublicizeConnection.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "connectionID = %@", connectionID)
        return try? context.fetch(request).first
    }

}

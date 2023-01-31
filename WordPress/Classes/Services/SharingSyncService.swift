import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressKit

/// SharingService is responsible for wrangling publicize services, publicize
/// connections, and keyring connections.
///
@objc class SharingSyncService: CoreDataService {

    /// Returns the remote to use with the service.
    ///
    /// - Parameter blog: The blog to use for the rest api.
    ///
    private func remoteForBlog(_ blog: Blog) -> SharingServiceRemote? {
        guard let api = blog.wordPressComRestApi() else {
            return nil
        }

        return SharingServiceRemote(wordPressComRestApi: api)
    }

    /// Syncs Publicize connections for the specified wpcom blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync publicize connections
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    @objc open func syncPublicizeConnectionsForBlog(_ blog: Blog, success: (() -> Void)?, failure: ((NSError?) -> Void)?) {
        let blogObjectID = blog.objectID
        guard let remote = remoteForBlog(blog) else {
            failure?(SharingSyncServiceError.siteWithNoRemote as NSError)
            return
        }

        remote.getPublicizeConnections(blog.dotComID!, success: { remoteConnections in

            // Process the results
            self.mergePublicizeConnectionsForBlog(blogObjectID, remoteConnections: remoteConnections, onComplete: success)
        },
        failure: failure)
    }

    /// Called when syncing Publicize connections. Merges synced and cached data, removing
    /// anything that does not exist on the server.  Saves the context.
    ///
    /// - Parameters:
    ///     - blogObjectID: the NSManagedObjectID of a `Blog`
    ///     - remoteConnections: An array of `RemotePublicizeConnection` objects to merge.
    ///     - onComplete: An optional callback block to be performed when core data has saved the changes.
    ///
    fileprivate func mergePublicizeConnectionsForBlog(_ blogObjectID: NSManagedObjectID, remoteConnections: [RemotePublicizeConnection], onComplete: (() -> Void)?) {
        coreDataStack.performAndSave({ context in
            var blog: Blog
            do {
                blog = try context.existingObject(with: blogObjectID) as! Blog
            } catch let error as NSError {
                DDLogError("Error fetching Blog: \(error)")
                // Because of the error we'll bail early, but we still need to call
                // the success callback if one was passed.
                return
            }

            let currentPublicizeConnections = self.allPublicizeConnections(for: blog, in: context)

            // Create or update based on the contents synced.
            let connectionsToKeep = remoteConnections.map { (remoteConnection) -> PublicizeConnection in
                let pubConnection = PublicizeConnection.createOrReplace(from: remoteConnection, in: context)
                pubConnection.blog = blog
                return pubConnection
            }

            // Delete any cached PublicizeServices that were not synced.
            for pubConnection in currentPublicizeConnections {
                if !connectionsToKeep.contains(pubConnection) {
                    context.delete(pubConnection)
                }
            }
        }, completion: { onComplete?() }, on: .main)
    }


    /// Returns an array of all cached `PublicizeConnection` objects.
    ///
    /// - Parameters
    ///     - blog: A `Blog` object
    ///
    /// - Returns: An array of `PublicizeConnection`.  The array is empty if no objects are cached.
    ///
    private func allPublicizeConnections(for blog: Blog, in context: NSManagedObjectContext) -> [PublicizeConnection] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: PublicizeConnection.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "blog = %@", blog)

        var connections: [PublicizeConnection]
        do {
            connections = try context.fetch(request) as! [PublicizeConnection]
        } catch let error as NSError {
            DDLogError("Error fetching Publicize Connections: \(error.localizedDescription)")
            connections = []
        }

        return connections
    }

    // Error for failure states
    enum SharingSyncServiceError: Error {
        case siteWithNoRemote
    }

}

import Foundation

/**
 SharingService is responsible for wrangling publicize services, publicize 
 connections, and keyring connections.
*/
public class SharingService : LocalCoreDataService
{

    // MARK: - Methods calling remote services


    /**
    Syncs the list of Publicize services.  The list is expected to very rarely change.

    @param success An optional success block accepting no parameters
    @param failure An optional failure block accepting an `NSError` parameter
    */
    public func syncPublicizeServices(success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let remote = SharingServiceRemote(api: apiForRequest())

        remote.getPublicizeServices( {(remoteServices:[RemotePublicizeService]) -> Void in
            // Process the results
            self.mergePublicizeServices(remoteServices, success: success)
        },
        failure: { (error: NSError!) -> Void in
            failure?(error)
        })
    }


    /**
    Fetches the current user's list of keyring connections. Nothing is saved to core data.
    The success block should accept an array of `KeyringConnection` objects.

    @param success An optional success block accepting an array of `KeyringConnection` objects
    @param failure An optional failure block accepting an `NSError` parameter
    */
    public func fetchKeyringConnections(success: ([KeyringConnection] -> Void)?, failure: (NSError! -> Void)?) {
        let remote = SharingServiceRemote(api: apiForRequest())

        remote.getKeyringConnections( {(keyringConnections:[KeyringConnection]) -> Void in
            // Just return the result
            success?(keyringConnections)
        },
        failure: { (error: NSError!) -> Void in
            failure?(error)
        })
    }


    /**
    Syncs Publicize connections for the specified wpcom blog.

    @param blog The `Blog` for which to sync publicize connections
    @param success An optional success block accepting no parameters.
    @param failure An optional failure block accepting an `NSError` parameter.
    */
    public func syncPublicizeConnectionsForBlog(blog:Blog, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let blogObjectID = blog.objectID
        let remote = SharingServiceRemote(api: apiForRequest())
        remote.getPublicizeConnections(blog.dotComID, success: {(remoteConnections:[RemotePublicizeConnection]) -> Void in
            // Process the results
            self.mergePublicizeConnectionsForBlog(blogObjectID, remoteConnections:remoteConnections, success: success)
        },
        failure: { (error: NSError!) -> Void in
            failure?(error)
        })
    }


    /**
    Creates a new publicize connection for the specified `Blog`, using the specified
    keyring.  Optionally the connection can target a particular external user account.

    @param blog The `Blog` for which to sync publicize connections
    @param keyring The `KeyringConnection` to use
    @param externalUserID An optional string representing a user ID on the external service.
    @param success An optional success block accepting a `PublicizeConnection` parameter.
    @param failure An optional failure block accepting an NSError parameter.
    */
    public func createPublicizeConnectionForBlog(blog:Blog,
        keyring:KeyringConnection,
        externalUserID:String?,
        success: (PublicizeConnection -> Void)?,
        failure: (NSError! -> Void)?)
    {

            let blogObjectID = blog.objectID
            let remote = SharingServiceRemote(api: apiForRequest())

            remote.createPublicizeConnection(blog.dotComID,
                keyringConnectionID: keyring.keyringID,
                externalUserID: externalUserID,
                success: {(remoteConnection:RemotePublicizeConnection) -> Void in
                    do {
                        let pubConn = try self.createPublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection)
                        success?(pubConn)

                    } catch let error as NSError {
                        DDLogSwift.logError("Error creating publicize connection from remote: \(error)")
                        failure?(error)
                    }

                },
                failure: { (error: NSError!) -> Void in
                    failure?(error)
                })

    }

    /**
    Deletes the specified `PublicizeConnection`.  The delete from core data is performed
    optimistically.  The caller's `failure` block should be responsible for resyncing
    the deleted connection.

    @param pubConn The `PublicizeConnection` to delete
    @param success An optional success block accepting no parameters.
    @param failure An optional failure block accepting an NSError parameter.
    */
    public func deletePublicizeConnection(pubConn:PublicizeConnection, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        // optimistically delete the connection locally.
        let siteID = pubConn.siteID;
        managedObjectContext.deleteObject(pubConn);
        ContextManager.sharedInstance().saveContext(managedObjectContext)

        let remote = SharingServiceRemote(api: apiForRequest())
        remote.deletePublicizeConnection(siteID, connectionID:pubConn.connectionID, success:success, failure:failure)
    }


    // MARK: - Public PublicizeService Methods

    /**
    Finds a cached `PublicizeService` matching the specified service name.

    @param name The name of the service. This is the `serviceID` attribute for a `PublicizeService` object.

    @return The requested `PublicizeService` or nil.
    */
    public func findPublicizeServiceNamed(name:String) -> PublicizeService? {
        let request = NSFetchRequest(entityName: PublicizeService.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "serviceID = %@", name)

        var services: [PublicizeService]
        do {
            services = try managedObjectContext.executeFetchRequest(request) as! [PublicizeService]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching Publicize Service named \(name) : \(error.localizedDescription)")
            services = []
        }

        return services.first
    }


    /**
    Returns an array of all cached `PublicizeService` objects.

    @return An array of `PublicizeService`.  The array is empty if no objects are cached.
    */
    public func allPublicizeServices() -> [PublicizeService] {
        let request = NSFetchRequest(entityName: PublicizeService.classNameWithoutNamespaces())
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        var services: [PublicizeService]
        do {
            services = try managedObjectContext.executeFetchRequest(request) as! [PublicizeService]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching Publicize Services: \(error.localizedDescription)")
            services = []
        }

        return services
    }


    // MARK: - Private PublicizeService Methods


    /**
    Called when syncing Publicize services. Merges synced and cached data, removing
    anything that does not exist on the server.  Saves the context.

    @param remoteServices An array of `RemotePublicizeService` objects to merge.
    @param success An optional callback block to be performed when core data has saved the changes.
    */
    private func mergePublicizeServices(remoteServices:[RemotePublicizeService], success:(() -> Void)? ) {
        managedObjectContext.performBlock {
            let currentPublicizeServices = self.allPublicizeServices()

            // Create or update based on the contents synced.
            let servicesToKeep = remoteServices.map { (let remoteService) -> PublicizeService in
                let pubService = self.createOrReplaceFromRemotePublicizeService(remoteService)
                return pubService
            }

            // Delete any cached PublicizeServices that were not synced.
            for pubService in currentPublicizeServices {
                if !servicesToKeep.contains(pubService) {
                    self.managedObjectContext.deleteObject(pubService)
                }
            }

            // Save all the things.
            ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                success?()
            })
        }
    }


    /**
    Composes a new `PublicizeService`, or updates an existing one, with data represented by the passed `RemotePublicizeService`.

    @return A `PublicizeService`.
    */
    private func createOrReplaceFromRemotePublicizeService(remoteService:RemotePublicizeService) -> PublicizeService {
        var pubService = findPublicizeServiceNamed(remoteService.serviceID)
        if pubService == nil {
            pubService = NSEntityDescription.insertNewObjectForEntityForName(PublicizeService.classNameWithoutNamespaces(),
                inManagedObjectContext: managedObjectContext) as? PublicizeService
        }
        pubService?.connectURL = remoteService.connectURL
        pubService?.detail = remoteService.detail
        pubService?.icon = remoteService.icon
        pubService?.jetpackModuleRequired = remoteService.jetpackModuleRequired
        pubService?.jetpackSupport = remoteService.jetpackSupport
        pubService?.label = remoteService.label
        pubService?.multipleExternalUserIDSupport = remoteService.multipleExternalUserIDSupport
        pubService?.order = remoteService.order
        pubService?.serviceID = remoteService.serviceID
        pubService?.type = remoteService.type

        return pubService!
    }


    // MARK: - Public PublicizeConnection Methods


    /**
    Finds a cached `PublicizeConnection` by its `connectionID`

    @param connectionID The ID of the `PublicizeConnection`.

    @return The requested `PublicizeConnection` or nil.
    */
    public func findPublicizeConnectionByID(connectionID:NSNumber) -> PublicizeConnection? {
        let request = NSFetchRequest(entityName: PublicizeConnection.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "connectionID = %@", connectionID)

        var services: [PublicizeConnection]
        do {
            services = try managedObjectContext.executeFetchRequest(request) as! [PublicizeConnection]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching Publicize Service with ID \(connectionID) : \(error.localizedDescription)")
            services = []
        }

        return services.first
    }


    /**
    Returns an array of all cached `PublicizeConnection` objects.

    @return An array of `PublicizeConnection`.  The array is empty if no objects are cached.
    */
    public func allPublicizeConnectionsForBlog(blog:Blog) -> [PublicizeConnection] {
        let request = NSFetchRequest(entityName: PublicizeConnection.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "blog = %@", blog)

        var connections: [PublicizeConnection]
        do {
            connections = try managedObjectContext.executeFetchRequest(request) as! [PublicizeConnection]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching Publicize Connections: \(error.localizedDescription)")
            connections = []
        }

        return connections
    }


    // MARK: - Private PublicizeConnection Methods


    /**
    Called when syncing Publicize connections. Merges synced and cached data, removing
    anything that does not exist on the server.  Saves the context.

    @param remoteConnections An array of `RemotePublicizeConnection` objects to merge.
    @param success An optional callback block to be performed when core data has saved the changes.
    */
    private func mergePublicizeConnectionsForBlog(blogObjectID:NSManagedObjectID, remoteConnections:[RemotePublicizeConnection], success:(() -> Void)? ) {
        managedObjectContext.performBlock { () -> Void in
            var blog:Blog
            do {
                blog = try self.managedObjectContext.existingObjectWithID(blogObjectID) as! Blog
            } catch let error as NSError {
                DDLogSwift.logError("Error fetching Blog: \(error)")
                // Because of the error we'll bail early, but we still need to call
                // the success callback if one was passed.
                success?()
                return
            }

            let currentPublicizeConnections = self.allPublicizeConnectionsForBlog(blog)

            // Create or update based on the contents synced.
            let connectionsToKeep = remoteConnections.map { (let remoteConnection) -> PublicizeConnection in
                let pubConnection = self.createOrReplaceFromRemotePublicizeConnection(remoteConnection)
                pubConnection.blog = blog
                return pubConnection
            }

            // Delete any cached PublicizeServices that were not synced.
            for pubConnection in currentPublicizeConnections {
                if !connectionsToKeep.contains(pubConnection) {
                    self.managedObjectContext.deleteObject(pubConnection)
                }
            }

            // Save all the things.
            ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: { () -> Void in
                success?()
            })
        }
    }


    /**
    Composes a new `PublicizeConnection`, or updates an existing one, with data represented by the passed `RemotePublicizeConnection`.

    @return A `PublicizeConnection`.
    */
    private func createOrReplaceFromRemotePublicizeConnection(remoteConnection:RemotePublicizeConnection) -> PublicizeConnection {
        var pubConnection = findPublicizeConnectionByID(remoteConnection.connectionID)
        if pubConnection == nil {
            pubConnection = NSEntityDescription.insertNewObjectForEntityForName(PublicizeConnection.classNameWithoutNamespaces(),
                inManagedObjectContext: managedObjectContext) as? PublicizeConnection
        }

        pubConnection?.connectionID = remoteConnection.connectionID
        pubConnection?.dateExpires = remoteConnection.dateExpires
        pubConnection?.dateIssued = remoteConnection.dateIssued
        pubConnection?.externalDisplay = remoteConnection.externalDisplay
        pubConnection?.externalFollowerCount = remoteConnection.externalFollowerCount
        pubConnection?.externalID = remoteConnection.externalID
        pubConnection?.externalName = remoteConnection.externalName
        pubConnection?.externalProfilePicture = remoteConnection.externalProfilePicture
        pubConnection?.externalProfileURL = remoteConnection.externalProfileURL
        pubConnection?.keyringConnectionID = remoteConnection.keyringConnectionID
        pubConnection?.keyringConnectionUserID = remoteConnection.keyringConnectionUserID
        pubConnection?.label = remoteConnection.label
        pubConnection?.refreshURL = remoteConnection.refreshURL
        pubConnection?.service = remoteConnection.service
        pubConnection?.status = remoteConnection.status
        pubConnection?.siteID = remoteConnection.siteID
        pubConnection?.userID = remoteConnection.userID

        return pubConnection!
    }


    /**
    Composes a new `PublicizeConnection`, with data represented by the passed `RemotePublicizeConnection`.
    Throws an error if unable to find a `Blog` for the `blogObjectID`

    @param blogObjectID And `NSManagedObjectID` for for a `Blog` entity.

    @return A `PublicizeConnection`.
    */
    private func createPublicizeConnectionForBlogWithObjectID(blogObjectID:NSManagedObjectID,
        remoteConnection:RemotePublicizeConnection) throws -> PublicizeConnection {

            let blog = try managedObjectContext.existingObjectWithID(blogObjectID) as! Blog
            let pubConn = createOrReplaceFromRemotePublicizeConnection(remoteConnection)
            pubConn.blog = blog

            return pubConn
    }


    // MARK : Private Instance Methods


    // Returns the API to use with the service
    private func apiForRequest() -> WordPressComApi {
        var api : WordPressComApi? = nil

        if let restApi = AccountService(managedObjectContext: managedObjectContext).defaultWordPressComAccount()?.restApi {
            api = restApi.hasCredentials() ? restApi : nil
        }

        if api == nil {
            // In practice this should never happen, but if it does let's try to detect it. 
            // Write to the error log if the api was nil, and trigger an assert to 
            // catch this in development/QA.
            api = WordPressComApi.anonymousApi()
            let error = "SharingService is not using a real WordPress.com account."
            DDLogSwift.logError(error)
            assert(false, error)
        }

        return api!
    }
}

import Foundation


/// SharingService is responsible for wrangling publicize services, publicize
/// connections, and keyring connections.
///
public class SharingService : LocalCoreDataService
{
    let SharingAPIErrorNotFound = "not_found"

    // MARK: - Publicize Related Methods


    /// Syncs the list of Publicize services.  The list is expected to very rarely change.
    ///
    /// - Parameters: 
    ///     - blog: The `Blog` for which to sync publicize services
    ///     - success: An optional success block accepting no parameters
    ///     - failure: An optional failure block accepting an `NSError` parameter
    ///
    public func syncPublicizeServicesForBlog(blog: Blog, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let remote = SharingServiceRemote(api: apiForBlog(blog))

        remote.getPublicizeServices( {(remoteServices: [RemotePublicizeService]) in
            // Process the results
            self.mergePublicizeServices(remoteServices, success: success)
        },
        failure: { (error: NSError!) in
            failure?(error)
        })
    }


    /// Fetches the current user's list of keyring connections. Nothing is saved to core data.
    /// The success block should accept an array of `KeyringConnection` objects.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync keyring connections
    ///     - success: An optional success block accepting an array of `KeyringConnection` objects
    ///     - failure: An optional failure block accepting an `NSError` parameter
    ///
    public func fetchKeyringConnectionsForBlog(blog: Blog, success: ([KeyringConnection] -> Void)?, failure: (NSError! -> Void)?) {
        let remote = SharingServiceRemote(api: apiForBlog(blog))

        remote.getKeyringConnections( {(keyringConnections: [KeyringConnection]) in
            // Just return the result
            success?(keyringConnections)
        },
        failure: { (error: NSError!) in
            failure?(error)
        })
    }


    /// Syncs Publicize connections for the specified wpcom blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync publicize connections
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    public func syncPublicizeConnectionsForBlog(blog: Blog, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let blogObjectID = blog.objectID
        let remote = SharingServiceRemote(api: apiForBlog(blog))
        remote.getPublicizeConnections(blog.dotComID, success: {(remoteConnections:[RemotePublicizeConnection]) in

            // Process the results
            self.mergePublicizeConnectionsForBlog(blogObjectID, remoteConnections: remoteConnections, onComplete: success)
        },
        failure: { (error: NSError!) in
            failure?(error)
        })
    }


    /// Creates a new publicize connection for the specified `Blog`, using the specified
    /// keyring.  Optionally the connection can target a particular external user account.
    ///
    /// - Parameters
    ///     - blog: The `Blog` for which to sync publicize connections
    ///     - keyring: The `KeyringConnection` to use
    ///     - externalUserID: An optional string representing a user ID on the external service.
    ///     - success: An optional success block accepting a `PublicizeConnection` parameter.
    ///     - failure: An optional failure block accepting an NSError parameter.
    ///
    public func createPublicizeConnectionForBlog(blog: Blog,
        keyring: KeyringConnection,
        externalUserID: String?,
        success: (PublicizeConnection -> Void)?,
        failure: (NSError! -> Void)?)
    {
        let blogObjectID = blog.objectID
        let remote = SharingServiceRemote(api: apiForBlog(blog))

        remote.createPublicizeConnection(blog.dotComID,
            keyringConnectionID: keyring.keyringID,
            externalUserID: externalUserID,
            success: {(remoteConnection: RemotePublicizeConnection) in
                do {
                    let pubConn = try self.createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection)
                    ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                        success?(pubConn)
                    })

                } catch let error as NSError {
                    DDLogSwift.logError("Error creating publicize connection from remote: \(error)")
                    failure?(error)
                }

            },
            failure: { (error: NSError!) in
                failure?(error)
            })
    }


    /// Update the specified `PublicizeConnection`.  The update to core data is performed
    /// optimistically. In case of failure the original value will be restored.
    ///
    /// - Parameters:
    ///     - shared: True if the connection should be shared with all users of the blog.
    ///     - pubConn: The `PublicizeConnection` to update
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an NSError parameter.
    ///
    public func updateSharedForBlog(blog: Blog,
        shared: Bool,
        forPublicizeConnection pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: (NSError! -> Void)?) {

            if pubConn.shared == shared {
                success?()
                return;
            }

            let oldValue = pubConn.shared
            pubConn.shared = shared
            ContextManager.sharedInstance().saveContext(managedObjectContext)

            let blogObjectID = blog.objectID
            let siteID = pubConn.siteID;
            let remote = SharingServiceRemote(api: apiForBlog(blog))
            remote.updatePublicizeConnectionWithID(pubConn.connectionID,
                shared: shared,
                forSite: siteID,
                success: {(remoteConnection: RemotePublicizeConnection) in
                    do {
                        _ = try self.createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection)
                        ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                            success?()
                        })

                    } catch let error as NSError {
                        DDLogSwift.logError("Error creating publicize connection from remote: \(error)")
                        failure?(error)
                    }

                },
                failure: { (error: NSError!) in
                    pubConn.shared = oldValue
                    ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                        failure?(error)
                    })
            })
    }


    /// Update the specified `PublicizeConnection`.  The update to core data is performed
    /// optimistically. In case of failure the original value will be restored.
    ///
    /// - Parameters:
    ///     - externalID: True if the connection should be shared with all users of the blog.
    ///     - pubConn: The `PublicizeConnection` to update
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an NSError parameter.
    ///
    public func updateExternalID(externalID: String,
        forBlog blog: Blog,
        forPublicizeConnection pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: (NSError! -> Void)?) {
            if pubConn.externalID == externalID {
                success?()
                return;
            }

            let blogObjectID = blog.objectID
            let siteID = pubConn.siteID;
            let remote = SharingServiceRemote(api: apiForBlog(blog))
            remote.updatePublicizeConnectionWithID(pubConn.connectionID,
                externalID: externalID,
                forSite: siteID,
                success: {(remoteConnection: RemotePublicizeConnection) in
                    do {
                        _ = try self.createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection)
                        ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                            success?()
                        })

                    } catch let error as NSError {
                        DDLogSwift.logError("Error creating publicize connection from remote: \(error)")
                        failure?(error)
                    }

                },
                failure: { (error: NSError!) in
                    failure?(error)

            })
    }


    /// Deletes the specified `PublicizeConnection`.  The delete from core data is performed
    /// optimistically.  The caller's `failure` block should be responsible for resyncing
    /// the deleted connection.
    ///
    /// - Parameters:
    ///     - pubConn: The `PublicizeConnection` to delete
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an NSError parameter.
    ///
    public func deletePublicizeConnectionForBlog(blog: Blog, pubConn: PublicizeConnection, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        // optimistically delete the connection locally.
        let siteID = pubConn.siteID;
        managedObjectContext.deleteObject(pubConn);
        ContextManager.sharedInstance().saveContext(managedObjectContext)

        let remote = SharingServiceRemote(api: apiForBlog(blog))
        remote.deletePublicizeConnection(siteID,
            connectionID: pubConn.connectionID,
            success: {
                success?()
            },
            failure: { (error:NSError!) in
                if let errorCode = error.userInfo[WordPressComApiErrorCodeKey] as? String {
                    if errorCode == self.SharingAPIErrorNotFound {
                        // This is a special situation. If the call to disconnect the service returns not_found then the service
                        // has probably already been disconnected and the call was made with stale data.
                        // Assume this is the case and treat this error as a successful disconnect.
                        success?()
                        return
                    }
                }
                failure?(error)
            })
    }


    // MARK: - Public PublicizeService Methods

    
    /// Finds a cached `PublicizeService` matching the specified service name.
    ///
    /// - Parameters:
    ///     - name: The name of the service. This is the `serviceID` attribute for a `PublicizeService` object.
    ///
    /// - Returns: The requested `PublicizeService` or nil.
    ///
    public func findPublicizeServiceNamed(name: String) -> PublicizeService? {
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


    /// Returns an array of all cached `PublicizeService` objects.
    ///
    /// - Returns: An array of `PublicizeService`.  The array is empty if no objects are cached.
    ///
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


    /// Called when syncing Publicize services. Merges synced and cached data, removing
    /// anything that does not exist on the server.  Saves the context.
    ///
    /// - Parameters
    ///     - remoteServices: An array of `RemotePublicizeService` objects to merge.
    ///     - success: An optional callback block to be performed when core data has saved the changes.
    ///
    private func mergePublicizeServices(remoteServices: [RemotePublicizeService], success: (() -> Void)? ) {
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


    /// Composes a new `PublicizeService`, or updates an existing one, with data represented by the passed `RemotePublicizeService`.
    ///
    /// - Parameters:
    ///     - remoteService: The remote publicize service representing a `PublicizeService`
    ///
    /// - Returns: A `PublicizeService`.
    ///
    private func createOrReplaceFromRemotePublicizeService(remoteService: RemotePublicizeService) -> PublicizeService {
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


    /// Finds a cached `PublicizeConnection` by its `connectionID`
    ///
    /// - Parameters:
    ///     - connectionID: The ID of the `PublicizeConnection`.
    ///
    /// - Returns: The requested `PublicizeConnection` or nil.
    ///
    public func findPublicizeConnectionByID(connectionID: NSNumber) -> PublicizeConnection? {
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


    /// Returns an array of all cached `PublicizeConnection` objects.
    ///
    /// - Parameters
    ///     - blog: A `Blog` object
    ///
    /// - Returns: An array of `PublicizeConnection`.  The array is empty if no objects are cached.
    ///
    public func allPublicizeConnectionsForBlog(blog: Blog) -> [PublicizeConnection] {
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


    /// Called when syncing Publicize connections. Merges synced and cached data, removing
    /// anything that does not exist on the server.  Saves the context.
    ///
    /// - Parameters:
    ///     - blogObjectID: the NSManagedObjectID of a `Blog`
    ///     - remoteConnections: An array of `RemotePublicizeConnection` objects to merge.
    ///     - onComplete: An optional callback block to be performed when core data has saved the changes.
    ///
    private func mergePublicizeConnectionsForBlog(blogObjectID: NSManagedObjectID, remoteConnections: [RemotePublicizeConnection], onComplete: (() -> Void)?) {
        managedObjectContext.performBlock {
            var blog: Blog
            do {
                blog = try self.managedObjectContext.existingObjectWithID(blogObjectID) as! Blog
            } catch let error as NSError {
                DDLogSwift.logError("Error fetching Blog: \(error)")
                // Because of the error we'll bail early, but we still need to call
                // the success callback if one was passed.
                onComplete?()
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
            ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                onComplete?()
            })
        }
    }


    /// Composes a new `PublicizeConnection`, or updates an existing one, with
    /// data represented by the passed `RemotePublicizeConnection`.
    /// 
    /// - Parameters:
    ///     - remoteConnection: The remote connection representing the publicize connection.
    ///
    /// - Returns: A `PublicizeConnection`.
    ///
    private func createOrReplaceFromRemotePublicizeConnection(remoteConnection: RemotePublicizeConnection) -> PublicizeConnection {
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
        pubConnection?.shared = remoteConnection.shared
        pubConnection?.status = remoteConnection.status
        pubConnection?.siteID = remoteConnection.siteID
        pubConnection?.userID = remoteConnection.userID

        return pubConnection!
    }


    /// Composes a new `PublicizeConnection`, with data represented by the passed `RemotePublicizeConnection`.
    /// Throws an error if unable to find a `Blog` for the `blogObjectID`
    /// 
    /// - Parameters:
    ///     - blogObjectID: And `NSManagedObjectID` for for a `Blog` entity.
    ///
    /// - Returns: A `PublicizeConnection`.
    ///
    private func createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID: NSManagedObjectID,
        remoteConnection: RemotePublicizeConnection) throws -> PublicizeConnection {

            let blog = try managedObjectContext.existingObjectWithID(blogObjectID) as! Blog
            let pubConn = createOrReplaceFromRemotePublicizeConnection(remoteConnection)
            pubConn.blog = blog

            return pubConn
    }


    // MARK: Sharing Button Related Methods

    /// Syncs `SharingButton`s for the specified wpcom blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync sharing buttons
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    public func syncSharingButtonsForBlog(blog: Blog, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let blogObjectID = blog.objectID
        let remote = SharingServiceRemote(api: apiForBlog(blog))
        remote.getSharingButtonsForSite(blog.dotComID,
            success: { (remoteButtons:[RemoteSharingButton]) in
                self.mergeSharingButtonsForBlog(blogObjectID, remoteSharingButtons: remoteButtons, onComplete: success)
            },
            failure: { (error: NSError!) in
                failure?(error)
        })
    }


    /// Pushes changes to the specified blog's `SharingButton`s back up to the blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to update sharing buttons
    ///     - sharingButtons: An array of `SharingButton` entities with changes either to order, or properties to sync back to the blog.
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    public func updateSharingButtonsForBlog(blog: Blog, sharingButtons: [SharingButton], success: (() -> Void)?, failure: (NSError! -> Void)?) {

        let blogObjectID = blog.objectID
        let remote = SharingServiceRemote(api: apiForBlog(blog))
        remote.updateSharingButtonsForSite(blog.dotComID,
            sharingButtons: remoteShareButtonsFromShareButtons(sharingButtons),
            success: { (remoteButtons:[RemoteSharingButton]) in
                self.mergeSharingButtonsForBlog(blogObjectID, remoteSharingButtons: remoteButtons, onComplete: success)
            },
            failure: { (error: NSError!) in
                failure?(error)
        })
    }


    /// Called when syncing sharng buttons. Merges synced and cached data, removing
    /// anything that does not exist on the server.  Saves the context.
    ///
    /// - Parameters:
    ///     - blogObjectID: the NSManagedObjectID of a `Blog`
    ///     - remoteSharingButtons: An array of `RemoteSharingButton` objects to merge.
    ///     - onComplete: An optional callback block to be performed when core data has saved the changes.
    ///
    private func mergeSharingButtonsForBlog(blogObjectID: NSManagedObjectID, remoteSharingButtons: [RemoteSharingButton], onComplete: (() -> Void)?) {
        managedObjectContext.performBlock {
            var blog: Blog
            do {
                blog = try self.managedObjectContext.existingObjectWithID(blogObjectID) as! Blog
            } catch let error as NSError {
                DDLogSwift.logError("Error fetching Blog: \(error)")
                // Because of the error we'll bail early, but we still need to call
                // the success callback if one was passed.
                onComplete?()
                return
            }

            let currentSharingbuttons = self.allSharingButtonsForBlog(blog)

            // Create or update based on the contents synced.
            let buttonsToKeep = remoteSharingButtons.map { (let remoteButton) -> SharingButton in
                return self.createOrReplaceFromRemoteSharingButton(remoteButton, blog: blog)
            }

            // Delete any cached PublicizeServices that were not synced.
            for button in currentSharingbuttons {
                if !buttonsToKeep.contains(button) {
                    self.managedObjectContext.deleteObject(button)
                }
            }

            // Save all the things.
            ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                onComplete?()
            })
        }
    }


    /// Returns an array of all cached `SharingButtons` objects.
    ///
    /// - Parameters
    ///     - blog: A `Blog` object
    ///
    /// - Returns: An array of `SharingButton`s.  The array is empty if no objects are cached.
    ///
    public func allSharingButtonsForBlog(blog: Blog) -> [SharingButton] {
        let request = NSFetchRequest(entityName: SharingButton.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "blog = %@", blog)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        var buttons: [SharingButton]
        do {
            buttons = try managedObjectContext.executeFetchRequest(request) as! [SharingButton]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching Publicize Connections: \(error.localizedDescription)")
            buttons = []
        }

        return buttons
    }


    /// Composes a new `SharingButton`, or updates an existing one, with
    /// data represented by the passed `RemoteSharingButton`.
    ///
    /// - Parameters:
    ///     - remoteButton: The remote connection representing the publicize connection.
    ///     - blog: The `Blog` that owns or will own the button.
    ///
    /// - Returns: A `SharingButton`.
    ///
    private func createOrReplaceFromRemoteSharingButton(remoteButton: RemoteSharingButton, blog: Blog) -> SharingButton {
        var shareButton = findSharingButtonByID(remoteButton.buttonID, blog: blog)
        if shareButton == nil {
            shareButton = NSEntityDescription.insertNewObjectForEntityForName(SharingButton.classNameWithoutNamespaces(),
                inManagedObjectContext: managedObjectContext) as? SharingButton
        }

        shareButton?.buttonID = remoteButton.buttonID
        shareButton?.name = remoteButton.name
        shareButton?.shortname = remoteButton.shortname
        shareButton?.custom = remoteButton.custom
        shareButton?.enabled = remoteButton.enabled
        shareButton?.visibility = remoteButton.visibility
        shareButton?.order = remoteButton.order
        shareButton?.blog = blog

        return shareButton!
    }


    /// Composes `RemoteSharingButton` objects from properties on an array of `SharingButton`s.
    ///
    /// - Parameters:
    ///     - shareButtons: An array of `SharingButton` entities.
    ///
    /// - Returns: An array of `RemoteSharingButton` objects.
    ///
    private func remoteShareButtonsFromShareButtons(shareButtons: [SharingButton]) -> [RemoteSharingButton] {
        return shareButtons.map { (let shareButton) -> RemoteSharingButton in
            let btn = RemoteSharingButton()
            btn.buttonID = shareButton.buttonID
            btn.name = shareButton.name
            btn.shortname = shareButton.shortname
            btn.custom = shareButton.custom
            btn.enabled = shareButton.enabled
            btn.visibility = shareButton.visibility
            btn.order = shareButton.order
            return btn
        }
    }


    /// Finds a cached `SharingButton` by its `buttonID` for the specified `Blog`
    ///
    /// - Parameters:
    ///     - buttonID: The button ID of the `sharingButton`.
    ///     - blog: The blog that owns the sharing button.
    ///
    /// - Returns: The requested `SharingButton` or nil.
    ///
    public func findSharingButtonByID(buttonID: String, blog: Blog) -> SharingButton? {
        let request = NSFetchRequest(entityName: SharingButton.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "buttonID = %@ AND blog = %@", buttonID, blog)

        var buttons: [SharingButton]
        do {
            buttons = try managedObjectContext.executeFetchRequest(request) as! [SharingButton]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching shareing button \(buttonID) : \(error.localizedDescription)")
            buttons = []
        }

        return buttons.first
    }


    // MARK: Private Instance Methods


    /// Returns the API to use with the service. 
    ///
    /// - Parameters:
    ///     - blog: The blog to use for the rest api.
    ///
    private func apiForBlog(blog: Blog) -> WordPressComApi {
        let api: WordPressComApi? =  blog.restApi()
        assert(api != nil)
        return api!
    }
}

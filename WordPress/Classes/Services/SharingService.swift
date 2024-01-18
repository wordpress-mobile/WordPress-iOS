import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressKit

/// SharingService is responsible for wrangling publicize services, publicize
/// connections, and keyring connections.
///
@objc class SharingService: NSObject {
    let SharingAPIErrorNotFound = "not_found"

    private let coreDataStack: CoreDataStackSwift

    /// The initialiser for Objective-C code.
    ///
    /// Using `ContextManager` as the argument becuase `CoreDataStackSwift` is not accessible from Objective-C code.
    @objc
    init(contextManager: ContextManager) {
        self.coreDataStack = contextManager
    }

    init(coreDataStack: CoreDataStackSwift) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Publicize Related Methods

    /// Syncs the list of Publicize services.  The list is expected to very rarely change.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync publicize services
    ///     - success: An optional success block accepting no parameters
    ///     - failure: An optional failure block accepting an `NSError` parameter
    ///
    @objc func syncPublicizeServicesForBlog(_ blog: Blog, success: (() -> Void)?, failure: ((NSError?) -> Void)?) {
        guard let remote = remoteForBlog(blog),
              let blogID = blog.dotComID else {
            return
        }

        remote.getPublicizeServices(for: blogID, success: { remoteServices in
            // Process the results
            self.mergePublicizeServices(remoteServices, success: success)
        }, failure: failure)
    }

    /// Fetches the current user's list of keyring connections. Nothing is saved to core data.
    /// The success block should accept an array of `KeyringConnection` objects.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync keyring connections
    ///     - success: An optional success block accepting an array of `KeyringConnection` objects
    ///     - failure: An optional failure block accepting an `NSError` parameter
    ///
    @objc func fetchKeyringConnectionsForBlog(_ blog: Blog, success: (([KeyringConnection]) -> Void)?, failure: ((NSError?) -> Void)?) {
        guard let remote = remoteForBlog(blog) else {
            return
        }
        remote.getKeyringConnections({ keyringConnections in
            // Just return the result
            success?(keyringConnections)
        },
        failure: failure)
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
    @objc func createPublicizeConnectionForBlog(_ blog: Blog,
        keyring: KeyringConnection,
        externalUserID: String?,
        success: ((PublicizeConnection) -> Void)?,
        failure: ((NSError?) -> Void)?) {
        let blogObjectID = blog.objectID
        guard let remote = remoteForBlog(blog) else {
            return
        }
        let dotComID = blog.dotComID!
        remote.createPublicizeConnection(
            dotComID,
            keyringConnectionID: keyring.keyringID,
            externalUserID: externalUserID,
            success: { remoteConnection in
                let properties = [
                    "service": keyring.service
                ]
                WPAppAnalytics.track(.sharingPublicizeConnected, withProperties: properties, withBlogID: dotComID)

                self.coreDataStack.performAndSave({ context -> NSManagedObjectID in
                    try self.createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection, in: context)
                }, completion: { result in
                    let transformed = result.flatMap { objectID in
                        Result {
                            let object = try self.coreDataStack.mainContext.existingObject(with: objectID)
                            return object as! PublicizeConnection
                        }
                    }
                    switch transformed {
                    case let .success(object):
                        success?(object)
                    case let .failure(error):
                        DDLogError("Error creating publicize connection from remote: \(error)")
                        failure?(error as NSError)
                    }
                }, on: .main)
            },
            failure: { (error: NSError?) in
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
    @objc func updateSharedForBlog(
        _ blog: Blog,
        shared: Bool,
        forPublicizeConnection pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        typealias PubConnUpdateResult = (oldValue: Bool, siteID: NSNumber, connectionID: NSNumber, service: String, remote: SharingServiceRemote?)

        let blogObjectID = blog.objectID
        coreDataStack.performAndSave({ context -> PubConnUpdateResult in
            let blogInContext = try context.existingObject(with: blogObjectID) as! Blog
            let pubConnInContext = try context.existingObject(with: pubConn.objectID) as! PublicizeConnection
            let oldValue = pubConnInContext.shared
            pubConnInContext.shared = shared
            return (
                oldValue: oldValue,
                siteID: pubConnInContext.siteID,
                connectionID: pubConnInContext.connectionID,
                service: pubConnInContext.service,
                remote: self.remoteForBlog(blogInContext)
            )
        }, completion: { result in
            switch result {
            case let .success(value):
                if value.oldValue == shared {
                    success?()
                    return
                }

                value.remote?.updatePublicizeConnectionWithID(
                    value.connectionID,
                    shared: shared,
                    forSite: value.siteID,
                    success: { remoteConnection in
                        let properties = [
                            "service": value.service,
                            "is_site_wide": NSNumber(value: shared).stringValue
                        ]
                        WPAppAnalytics.track(.sharingPublicizeConnectionAvailableToAllChanged, withProperties: properties, withBlogID: value.siteID)

                        self.coreDataStack.performAndSave({ context in
                            try self.createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection, in: context)
                        }, completion: { result in
                            switch result {
                            case .success:
                                success?()
                            case let .failure(error):
                                DDLogError("Error creating publicize connection from remote: \(error)")
                                failure?(error as NSError)
                            }
                        }, on: .main)
                    },
                    failure: { (error: NSError?) in
                        self.coreDataStack.performAndSave({ context in
                            let pubConnInContext = try context.existingObject(with: pubConn.objectID) as! PublicizeConnection
                            pubConnInContext.shared = value.oldValue
                        }, completion: { _ in
                            failure?(error)
                        }, on: .main)
                    }
                )
            case let .failure(error):
                failure?(error as NSError)
            }
        }, on: .main)
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
    @objc func updateExternalID(_ externalID: String,
        forBlog blog: Blog,
        forPublicizeConnection pubConn: PublicizeConnection,
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?) {
            if pubConn.externalID == externalID {
                success?()
                return
            }

            let blogObjectID = blog.objectID
            let siteID = pubConn.siteID
            guard let remote = remoteForBlog(blog) else {
                return
            }
            remote.updatePublicizeConnectionWithID(pubConn.connectionID,
                externalID: externalID,
                forSite: siteID,
                success: { remoteConnection in
                    self.coreDataStack.performAndSave({ context in
                        try self.createOrReplacePublicizeConnectionForBlogWithObjectID(blogObjectID, remoteConnection: remoteConnection, in: context)
                    }, completion: { result in
                        switch result {
                        case .success:
                            success?()
                        case let .failure(error):
                            DDLogError("Error creating publicize connection from remote: \(error)")
                            failure?(error as NSError)
                        }
                    }, on: .main)
                },
                failure: failure)
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
    @objc func deletePublicizeConnectionForBlog(_ blog: Blog, pubConn: PublicizeConnection, success: (() -> Void)?, failure: ((NSError?) -> Void)?) {
        // optimistically delete the connection locally.
        coreDataStack.performAndSave({ context in
            let blogInContext = try context.existingObject(with: blog.objectID) as! Blog
            let pubConnInContext = try context.existingObject(with: pubConn.objectID) as! PublicizeConnection

            let siteID = pubConnInContext.siteID
            context.delete(pubConnInContext)
            return (siteID, pubConnInContext.connectionID, pubConnInContext.service, self.remoteForBlog(blogInContext))
        }, completion: { result in
            switch result {
            case let .success((siteID, connectionID, service, remote)):
                remote?.deletePublicizeConnection(
                    siteID,
                    connectionID: connectionID,
                    success: {
                        let properties = [
                            "service": service
                        ]
                        WPAppAnalytics.track(.sharingPublicizeDisconnected, withProperties: properties, withBlogID: siteID)
                        success?()
                    },
                    failure: { (error: NSError?) in
                        if let errorCode = error?.userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String {
                            if errorCode == self.SharingAPIErrorNotFound {
                                // This is a special situation. If the call to disconnect the service returns not_found then the service
                                // has probably already been disconnected and the call was made with stale data.
                                // Assume this is the case and treat this error as a successful disconnect.
                                success?()
                                return
                            }
                        }
                        failure?(error)
                    }
                )
            case let .failure(error):
                failure?(error as NSError)
            }
        }, on: .main)
    }

    // MARK: - Private PublicizeService Methods

    /// Called when syncing Publicize services. Merges synced and cached data, removing
    /// anything that does not exist on the server.  Saves the context.
    ///
    /// - Parameters
    ///     - remoteServices: An array of `RemotePublicizeService` objects to merge.
    ///     - success: An optional callback block to be performed when core data has saved the changes.
    ///
    private func mergePublicizeServices(_ remoteServices: [RemotePublicizeService], success: (() -> Void)? ) {
        coreDataStack.performAndSave({ context in
            let currentPublicizeServices = (try? PublicizeService.allPublicizeServices(in: context)) ?? []

            // Create or update based on the contents synced.
            let servicesToKeep = remoteServices.map { (remoteService) -> PublicizeService in
                self.createOrReplaceFromRemotePublicizeService(remoteService, in: context)
            }

            // Delete any cached PublicizeServices that were not synced.
            for pubService in currentPublicizeServices {
                if !servicesToKeep.contains(pubService) {
                    context.delete(pubService)
                }
            }
        }, completion: success, on: .main)
    }

    /// Composes a new `PublicizeService`, or updates an existing one, with data represented by the passed `RemotePublicizeService`.
    ///
    /// - Parameter remoteService: The remote publicize service representing a `PublicizeService`
    ///
    /// - Returns: A `PublicizeService`.
    ///
    private func createOrReplaceFromRemotePublicizeService(_ remoteService: RemotePublicizeService, in context: NSManagedObjectContext) -> PublicizeService {
        var pubService = try? PublicizeService.lookupPublicizeServiceNamed(remoteService.serviceID, in: context)
        if pubService == nil {
            pubService = NSEntityDescription.insertNewObject(forEntityName: PublicizeService.classNameWithoutNamespaces(),
                into: context) as? PublicizeService
        }
        pubService?.connectURL = remoteService.connectURL
        pubService?.detail = remoteService.detail
        pubService?.externalUsersOnly = remoteService.externalUsersOnly
        pubService?.icon = remoteService.icon
        pubService?.jetpackModuleRequired = remoteService.jetpackModuleRequired
        pubService?.jetpackSupport = remoteService.jetpackSupport
        pubService?.label = remoteService.label
        pubService?.multipleExternalUserIDSupport = remoteService.multipleExternalUserIDSupport
        pubService?.order = remoteService.order
        pubService?.serviceID = remoteService.serviceID
        pubService?.type = remoteService.type
        pubService?.status = (remoteService.status.isEmpty ? PublicizeService.defaultStatus : remoteService.status)

        return pubService!
    }

    // MARK: - Private PublicizeConnection Methods

    /// Composes a new `PublicizeConnection`, with data represented by the passed `RemotePublicizeConnection`.
    /// Throws an error if unable to find a `Blog` for the `blogObjectID`
    ///
    /// - Parameter blogObjectID: And `NSManagedObjectID` for for a `Blog` entity.
    ///
    /// - Returns: A `PublicizeConnection`.
    ///
    private func createOrReplacePublicizeConnectionForBlogWithObjectID(
        _ blogObjectID: NSManagedObjectID,
        remoteConnection: RemotePublicizeConnection,
        in context: NSManagedObjectContext
    ) throws -> NSManagedObjectID {
        let blog = try context.existingObject(with: blogObjectID) as! Blog
        let pubConn = PublicizeConnection.createOrReplace(from: remoteConnection, in: context)
        pubConn.blog = blog

        try context.obtainPermanentIDs(for: [pubConn])

        return pubConn.objectID
    }

    // MARK: Sharing Button Related Methods

    /// Syncs `SharingButton`s for the specified wpcom blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync sharing buttons
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    @objc func syncSharingButtonsForBlog(_ blog: Blog, success: (() -> Void)?, failure: ((NSError?) -> Void)?) {
        let blogObjectID = blog.objectID
        guard let remote = remoteForBlog(blog) else {
            return
        }

        remote.getSharingButtonsForSite(blog.dotComID!,
            success: { (remoteButtons: [RemoteSharingButton]) in
                self.mergeSharingButtonsForBlog(blogObjectID, remoteSharingButtons: remoteButtons, onComplete: success)
            },
            failure: failure)
    }

    /// Pushes changes to the specified blog's `SharingButton`s back up to the blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to update sharing buttons
    ///     - sharingButtons: An array of `SharingButton` entities with changes either to order, or properties to sync back to the blog.
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    @objc func updateSharingButtonsForBlog(_ blog: Blog, sharingButtons: [SharingButton], success: (() -> Void)?, failure: ((NSError?) -> Void)?) {

        let blogObjectID = blog.objectID
        guard let remote = remoteForBlog(blog) else {
            return
        }
        remote.updateSharingButtonsForSite(blog.dotComID!,
            sharingButtons: remoteShareButtonsFromShareButtons(sharingButtons),
            success: { (remoteButtons: [RemoteSharingButton]) in
                self.mergeSharingButtonsForBlog(blogObjectID, remoteSharingButtons: remoteButtons, onComplete: success)
            },
            failure: failure)
    }

    /// Called when syncing sharng buttons. Merges synced and cached data, removing
    /// anything that does not exist on the server.  Saves the context.
    ///
    /// - Parameters:
    ///     - blogObjectID: the NSManagedObjectID of a `Blog`
    ///     - remoteSharingButtons: An array of `RemoteSharingButton` objects to merge.
    ///     - onComplete: An optional callback block to be performed when core data has saved the changes.
    ///
    private func mergeSharingButtonsForBlog(_ blogObjectID: NSManagedObjectID, remoteSharingButtons: [RemoteSharingButton], onComplete: (() -> Void)?) {
        coreDataStack.performAndSave({ context in
            let blog = try context.existingObject(with: blogObjectID) as! Blog

            let currentSharingbuttons = try SharingButton.allSharingButtons(for: blog, in: context)

            // Create or update based on the contents synced.
            let buttonsToKeep = remoteSharingButtons.map { (remoteButton) -> SharingButton in
                return self.createOrReplaceFromRemoteSharingButton(remoteButton, blog: blog, in: context)
            }

            // Delete any cached PublicizeServices that were not synced.
            for button in currentSharingbuttons {
                if !buttonsToKeep.contains(button) {
                    context.delete(button)
                }
            }
        }, completion: { _ in
            onComplete?()
        }, on: .main)
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
    private func createOrReplaceFromRemoteSharingButton(_ remoteButton: RemoteSharingButton, blog: Blog, in context: NSManagedObjectContext) -> SharingButton {
        var shareButton = try? SharingButton.lookupSharingButton(byID: remoteButton.buttonID, for: blog, in: context)
        if shareButton == nil {
            shareButton = NSEntityDescription.insertNewObject(forEntityName: SharingButton.classNameWithoutNamespaces(),
                into: context) as? SharingButton
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
    private func remoteShareButtonsFromShareButtons(_ shareButtons: [SharingButton]) -> [RemoteSharingButton] {
        return shareButtons.map { (shareButton) -> RemoteSharingButton in
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

    // MARK: Private Instance Methods

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
}

import Foundation
import WordPressData
import WordPressKit

/// SharingService is responsible for wrangling sharing buttons.
///
@objc public class SharingService: NSObject {
    let SharingAPIErrorNotFound = "not_found"

    private let coreDataStack: CoreDataStackSwift

    /// The initialiser for Objective-C code.
    ///
    /// Using `ContextManager` as the argument because `CoreDataStackSwift` is not accessible from Objective-C code.
    @objc
    public init(contextManager: ContextManager) {
        self.coreDataStack = contextManager
    }

    init(coreDataStack: CoreDataStackSwift) {
        self.coreDataStack = coreDataStack
    }

    // MARK: Sharing Button Related Methods

    /// Syncs `SharingButton`s for the specified wpcom blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to sync sharing buttons
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    @objc public func syncSharingButtonsForBlog(_ blog: Blog, success: (() -> Void)?, failure: ((NSError?) -> Void)?) {
        let blogObjectID = blog.objectID
        guard let remote = remoteForBlog(blog) else {
            return
        }

        remote.getSharingButtonsForSite(
            blog.dotComID!,
            success: { (remoteButtons: [RemoteSharingButton]) in
                self.mergeSharingButtonsForBlog(blogObjectID, remoteSharingButtons: remoteButtons, onComplete: success)
            },
            failure: failure
        )
    }

    /// Pushes changes to the specified blog's `SharingButton`s back up to the blog.
    ///
    /// - Parameters:
    ///     - blog: The `Blog` for which to update sharing buttons
    ///     - sharingButtons: An array of `SharingButton` entities with changes either to order, or properties to sync back to the blog.
    ///     - success: An optional success block accepting no parameters.
    ///     - failure: An optional failure block accepting an `NSError` parameter.
    ///
    @objc public func updateSharingButtonsForBlog(
        _ blog: Blog,
        sharingButtons: [SharingButton],
        success: (() -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {

        let blogObjectID = blog.objectID
        guard let remote = remoteForBlog(blog) else {
            return
        }
        remote.updateSharingButtonsForSite(
            blog.dotComID!,
            sharingButtons: remoteShareButtonsFromShareButtons(sharingButtons),
            success: { (remoteButtons: [RemoteSharingButton]) in
                self.mergeSharingButtonsForBlog(blogObjectID, remoteSharingButtons: remoteButtons, onComplete: success)
            },
            failure: failure
        )
    }

    /// Called when syncing sharing buttons. Merges synced and cached data, removing
    /// anything that does not exist on the server. Saves the context.
    ///
    /// - Parameters:
    ///     - blogObjectID: the NSManagedObjectID of a `Blog`
    ///     - remoteSharingButtons: An array of `RemoteSharingButton` objects to merge.
    ///     - onComplete: An optional callback block to be performed when core data has saved the changes.
    ///
    private func mergeSharingButtonsForBlog(
        _ blogObjectID: NSManagedObjectID,
        remoteSharingButtons: [RemoteSharingButton],
        onComplete: (() -> Void)?
    ) {
        coreDataStack.performAndSave(
            { context in
                let blog = try context.existingObject(with: blogObjectID) as! Blog

                let currentSharingbuttons = try SharingButton.allSharingButtons(for: blog, in: context)

                // Create or update based on the contents synced.
                let buttonsToKeep = remoteSharingButtons.map { remoteButton -> SharingButton in
                    self.createOrReplaceFromRemoteSharingButton(remoteButton, blog: blog, in: context)
                }

                // Delete any cached SharingButtons that were not synced.
                for button in currentSharingbuttons {
                    if !buttonsToKeep.contains(button) {
                        context.delete(button)
                    }
                }
            },
            completion: { _ in
                onComplete?()
            },
            on: .main
        )
    }

    /// Composes a new `SharingButton`, or updates an existing one, with
    /// data represented by the passed `RemoteSharingButton`.
    ///
    /// - Parameters:
    ///     - remoteButton: The remote sharing button to create or update from.
    ///     - blog: The `Blog` that owns or will own the button.
    ///
    /// - Returns: A `SharingButton`.
    ///
    private func createOrReplaceFromRemoteSharingButton(
        _ remoteButton: RemoteSharingButton,
        blog: Blog,
        in context: NSManagedObjectContext
    ) -> SharingButton {
        var shareButton = try? SharingButton.lookupSharingButton(byID: remoteButton.buttonID, for: blog, in: context)
        if shareButton == nil {
            shareButton =
                NSEntityDescription.insertNewObject(
                    forEntityName: SharingButton.entityName(),
                    into: context
                ) as? SharingButton
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
        shareButtons.map { shareButton -> RemoteSharingButton in
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
        guard let api = blog.wordPressComRestApi else {
            return nil
        }

        return SharingServiceRemote(wordPressComRestApi: api)
    }
}

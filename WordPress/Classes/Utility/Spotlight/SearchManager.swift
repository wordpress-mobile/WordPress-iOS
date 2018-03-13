import UIKit
import CoreSpotlight
import MobileCoreServices

public typealias SearchManagerCompletion = ((Error?) -> Void)?

/// Encapsulates CoreSpotlight operations for WPiOS
///
@objc class SearchManager: NSObject {

    // MARK: - Singleton

    @objc static let shared: SearchManager = SearchManager()
    private override init() {}

    // MARK: - Indexing

    /// Index an item to the on-device index
    ///
    /// - Parameters:
    ///   - item: the item to be indexed
    ///
    func index(_ item: SearchableItemConvertable) {
        index([item])
    }

    /// Index items to the on-device index
    ///
    /// - Parameters:
    ///   - items: the items to be indexed
    ///
    func index(_ items: [SearchableItemConvertable]) {
        let items = items.map { $0.indexableItem() }
        CSSearchableIndex.default().indexSearchableItems(items, completionHandler: { (error: Error?) -> Void in
            guard let error = error else {
                DDLogDebug("Successfully indexed post.")
                return
            }
            DDLogError("Could not index post. Error \(error)")
        })

    }

    // MARK: - Removal

    /// Remove an item from the on-device index
    ///
    /// - Parameters:
    ///   - item: item to remove
    ///   - completion: called when the item is deleted from the index
    ///
    func deleteSearchableItem(_ item: SearchableItemConvertable, completion: SearchManagerCompletion = nil) {
        deleteSearchableItems([item], completion: completion)
    }

    /// Remove items from the on-device index
    ///
    /// - Parameters:
    ///   - items: items to remove
    ///   - completion: called when the items are deleted from the index
    ///
    func deleteSearchableItems(_ items: [SearchableItemConvertable], completion: SearchManagerCompletion = nil) {
        let ids = items.map { $0.uniqueIdentifier }
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids, completionHandler: completion)
    }

    /// Removes all items with the given domain identifier from the on-device index
    ///
    /// - Parameters:
    ///   - domain: the domain identifier
    ///   - completion: called when removal of the domain items is complete
    ///
    func deleteAllSearchableItemsFromDomain(_ domain: String, completion: SearchManagerCompletion = nil) {
        deleteAllSearchableItemsFromDomains([domain])
    }

    /// Removes all items with the given domain identifiers from the on-device index
    ///
    /// - Parameters:
    ///   - domains: the domain identifiers
    ///   - completion: called when removal of the domain items is complete
    ///
    func deleteAllSearchableItemsFromDomains(_ domains: [String], completion: SearchManagerCompletion = nil) {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: domains, completionHandler: completion)
    }

    /// Removes *all* items from the on-device index.
    ///
    /// Note: Be careful, this clears the entire index!
    ///
    /// - Parameters:
    ///   - completion: called when removal of all indexed items is complete
    ///
    func deleteAllSearchableItems(completion: SearchManagerCompletion = nil) {
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: completion)
    }

    // MARK: - NSUserActivity Handling

    /// Handle a NSUserAcitivity
    ///
    /// - Parameter activity: NSUserActivity that opened the app
    /// - Returns: true if it was handled correctly and activitytype was `CSSearchableItemActionType`, otherwise false
    ///
    @discardableResult
    @objc static func handle(activity: NSUserActivity?) -> Bool {
        guard activity?.activityType == CSSearchableItemActionType else {
            return false
        }

        guard let compositeIdentifier = activity?.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }

        let (domain, identifier) = SearchIdentifierGenerator.decomposeFromUniqueIdentifier(compositeIdentifier)
        // FIXME: Do something here!

        return true
    }
}

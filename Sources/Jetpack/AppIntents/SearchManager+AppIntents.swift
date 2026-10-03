import CoreSpotlight
import Foundation
import WordPressData

// The Jetpack-app-only side of the Spotlight entity association seam declared
// in SearchManager.swift. This file compiles only into the Jetpack app target,
// which is the one that exposes App Intents entities.
extension SearchManager: SearchableItemEntityAssociating {
    func associateAppEntities(from item: SearchableItemConvertable, to searchableItem: CSSearchableItem) {
        guard #available(iOS 18, *) else {
            return
        }
        switch item {
        case let post as AbstractPost:
            if let entity = PostEntity(post: post) {
                searchableItem.associateAppEntity(entity, priority: 0)
            }
        case let post as ReaderPost:
            if let entity = ReaderPostEntity(post: post) {
                searchableItem.associateAppEntity(entity, priority: 0)
            }
        default:
            break
        }
    }
}

extension SearchManager {
    /// Opens the post an App Intent entity identifier points to, throwing the
    /// error the system should show when it cannot.
    @MainActor
    func openForAppIntent(withUniqueIdentifier identifier: String) async throws {
        guard AccountHelper.isLoggedIn else {
            throw AppIntentOpenError.notLoggedIn
        }
        guard await openItem(withUniqueIdentifier: identifier, source: .appIntent) else {
            throw AppIntentOpenError.postNotFound
        }
    }
}

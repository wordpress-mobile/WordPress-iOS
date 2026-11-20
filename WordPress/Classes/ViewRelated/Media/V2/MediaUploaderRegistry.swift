import CoreData
import Foundation
import WordPressCore
import WordPressData
import WordPressMediaLibrary

@MainActor
final class MediaUploaderRegistry {
    static let shared = MediaUploaderRegistry()

    private var uploaders: [TaggedManagedObjectID<Blog>: MediaUploader] = [:]
    private let clientFactory: WordPressClientFactory
    private var deletionObserver: NSObjectProtocol?

    /// Uploader teardown keys off actual Core Data deletion rather than
    /// explicit removal call sites, so every path that deletes a `Blog`
    /// (site deletion, Jetpack disconnect, sync-driven cleanup of dead
    /// blogs, and the account cascade on logout) is covered, while blogs
    /// that survive (self-hosted sites after a WordPress.com-only logout)
    /// keep their uploaders and any in-flight work.
    init(
        clientFactory: WordPressClientFactory = .shared,
        mainContext: NSManagedObjectContext = ContextManager.shared.mainContext
    ) {
        self.clientFactory = clientFactory
        deletionObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: mainContext,
            queue: nil
        ) { [weak self] notification in
            guard let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> else {
                return
            }
            let blogIDs = deleted.compactMap { ($0 as? Blog)?.objectID }
            if blogIDs.isEmpty {
                return
            }
            // The main context posts its change notifications on the main
            // thread, so hop into the @MainActor handler without an async gap.
            MainActor.assumeIsolated {
                self?.tearDownUploaders(forDeletedBlogIDs: blogIDs)
            }
        }
    }

    deinit {
        if let deletionObserver {
            NotificationCenter.default.removeObserver(deletionObserver)
        }
    }

    func uploader(for blog: Blog) throws -> MediaUploader {
        let id = TaggedManagedObjectID<Blog>(blog)
        // Built here, before any async hop, because the factory reads the
        // Blog on its main managed object context; only the Sendable policy
        // value crosses into the update Task below.
        let policy = MediaUploadPolicyFactory.make(from: blog)
        if let existing = uploaders[id] {
            // MediaSettings (like Remove Location) or refreshed blog options
            // may have changed since this uploader was cached. Push a fresh
            // policy so new enqueues honor them.
            Task { await existing.updatePolicy(policy) }
            return existing
        }

        let site = try WordPressSite(blog: blog)
        let client = clientFactory.instance(for: site)
        let uploader = MediaUploader(client: client, policy: policy)
        uploaders[id] = uploader
        return uploader
    }

    func hasUploader(blogID: TaggedManagedObjectID<Blog>) -> Bool {
        uploaders[blogID] != nil
    }

    /// Removal call sites should derive the `TaggedManagedObjectID` from
    /// the `Blog` while still on its managed object context, then pass it
    /// here. Capturing the `Blog` itself across the launched `Task`'s
    /// async boundary risks resolving a deleted-or-wrong-context object.
    func tearDown(blogID: TaggedManagedObjectID<Blog>) async {
        guard let uploader = uploaders.removeValue(forKey: blogID) else { return }
        await uploader.tearDown()
    }

    func tearDownAll() async {
        let snapshot = uploaders
        uploaders.removeAll()
        for (_, uploader) in snapshot {
            await uploader.tearDown()
        }
    }

    private func tearDownUploaders(forDeletedBlogIDs blogIDs: [NSManagedObjectID]) {
        for key in uploaders.keys where blogIDs.contains(key.objectID) {
            guard let uploader = uploaders.removeValue(forKey: key) else { continue }
            Task { await uploader.tearDown() }
        }
    }
}

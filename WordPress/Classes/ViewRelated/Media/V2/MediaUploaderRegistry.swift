import Foundation
import WordPressCore
import WordPressData
import WordPressMediaLibrary

@MainActor
final class MediaUploaderRegistry {
    static let shared = MediaUploaderRegistry()

    private var uploaders: [TaggedManagedObjectID<Blog>: MediaUploader] = [:]
    private let clientFactory: WordPressClientFactory

    init(clientFactory: WordPressClientFactory = .shared) {
        self.clientFactory = clientFactory
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
}

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
        if let existing = uploaders[id] { return existing }

        let site = try WordPressSite(blog: blog)
        let client = clientFactory.instance(for: site)
        let policy = MediaUploadPolicyFactory.make(from: blog)
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

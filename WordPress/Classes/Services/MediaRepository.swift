import Foundation

final class MediaRepository {

    enum Error: Swift.Error {
        case mediaNotFound
        case remoteAPIUnavailable
        case unknown
    }

    private let coreDataStack: CoreDataStackSwift
    private let remoteFactory: MediaServiceRemoteFactory

    init(coreDataStack: CoreDataStackSwift, remoteFactory: MediaServiceRemoteFactory = .init()) {
        self.coreDataStack = coreDataStack
        self.remoteFactory = remoteFactory
    }

    /// Get the Media object from the server using the blog and the mediaID as the identifier of the resource
    func getMedia(withID mediaID: NSNumber, in blogID: TaggedManagedObjectID<Blog>) async throws -> TaggedManagedObjectID<Media> {
        let remote = try await remote(for: blogID)
        let remoteMedia: RemoteMedia? = try await withCheckedThrowingContinuation { continuation in
            remote.getMediaWithID(
                mediaID, success: continuation.resume(returning:),
                failure: { continuation.resume(throwing: $0 ?? MediaRepository.Error.unknown) })
        }
        guard let remoteMedia else {
            throw MediaRepository.Error.mediaNotFound
        }

        return try await coreDataStack.performAndSave { context in
            let blog = try context.existingObject(with: blogID)
            let media = Media.existingMediaWith(mediaID: mediaID, inBlog: blog) ?? Media.makeMedia(blog: blog)
            MediaHelper.update(media: media, with: remoteMedia)
            return TaggedManagedObjectID(media)
        }
    }

    /// Deletes the Media object from the server. Note the Media is deleted, not trashed.
    func delete(_ mediaID: TaggedManagedObjectID<Media>) async throws {
        // Delete the media from WordPress Media Library
        let queryResult: (MediaServiceRemote, RemoteMedia)? = try await coreDataStack.performQuery { [remoteFactory] context in
            guard let media = try? context.existingObject(with: mediaID) else {
                return nil
            }
            // No need to delete the media from Media Library if it's not synced
            if media.remoteStatus != .sync {
                return nil
            }
            let remote = try remoteFactory.remote(for: media.blog)
            return (remote, RemoteMedia.from(media))
        }
        if let queryResult {
            let (remote, remoteMedia) = queryResult

            try await withCheckedThrowingContinuation { [remote] continuation in
                remote.delete(
                    remoteMedia,
                    success: { continuation.resume(returning: ()) },
                    failure: { continuation.resume(throwing: $0!) }
                )
            }
        }

        // Delete the media locally from Core Data.
        //
        // Considering the intent of calling this method is to delete the media object,
        // when it doesn't exist, we can treat the flow as success, since the intent is fulfilled.
        try? await coreDataStack.performAndSave { context in
            let media = try context.existingObject(with: mediaID)
            context.delete(media)
        }
    }

}

private extension MediaRepository {
    func remote(for blogID: TaggedManagedObjectID<Blog>) async throws -> MediaServiceRemote {
        try await coreDataStack.performQuery { [remoteFactory] context in
            let blog = try context.existingObject(with: blogID)
            return try remoteFactory.remote(for: blog)
        }
    }
}

@objc class MediaServiceRemoteFactory: NSObject {

    @objc(remoteForBlog:error:)
    func remote(for blog: Blog) throws -> MediaServiceRemote {
        if blog.supports(.wpComRESTAPI), let dotComID = blog.dotComID, let api = blog.wordPressComRestApi() {
            return MediaServiceRemoteREST(wordPressComRestApi: api, siteID: dotComID)
        }

        if let username = blog.username, let password = blog.password, let api = blog.xmlrpcApi {
            return MediaServiceRemoteXMLRPC(api: api, username: username, password: password)
        }

        throw MediaRepository.Error.remoteAPIUnavailable
    }

}

extension MediaServiceRemote {

    func getMediaLibraryCount(forMediaTypes types: [MediaType]) async throws -> Int {
        try await getMediaLibraryCount(forMediaTypes: types.map(Media.string(from:)))
    }

    func getMediaLibraryCount(forMediaTypes mediaTypes: [String]) async throws -> Int {
        var total = 0
        for type in mediaTypes {
            total += try await self.getMediaLibraryCount(forMediaType: type)
        }
        return total
    }

    private func getMediaLibraryCount(forMediaType type: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            self.getMediaLibraryCount(
                forType: type,
                withSuccess: continuation.resume(returning:),
                failure: { continuation.resume(throwing: $0!) }
            )
        }
    }

}

extension RemoteMedia {

    @objc(remoteMediaWithMedia:)
    static func from(_ media: Media) -> RemoteMedia {
        let remoteMedia = RemoteMedia()
        remoteMedia.mediaID = media.mediaID
        remoteMedia.url = media.remoteURL.flatMap(URL.init(string:))
        remoteMedia.largeURL = media.remoteLargeURL.flatMap(URL.init(string:))
        remoteMedia.mediumURL = media.remoteMediumURL.flatMap(URL.init(string:))
        remoteMedia.date = media.creationDate
        remoteMedia.file = media.filename
        remoteMedia.`extension` = media.fileExtension() ?? "unknown"
        remoteMedia.title = media.title
        remoteMedia.caption = media.caption
        remoteMedia.descriptionText = media.desc
        remoteMedia.alt = media.alt
        remoteMedia.height = media.height
        remoteMedia.width = media.width
        remoteMedia.localURL = media.absoluteLocalURL
        remoteMedia.mimeType = media.mimeType
        remoteMedia.videopressGUID = media.videopressGUID
        remoteMedia.remoteThumbnailURL = media.remoteThumbnailURL
        remoteMedia.postID = media.postID
        return remoteMedia
    }

}

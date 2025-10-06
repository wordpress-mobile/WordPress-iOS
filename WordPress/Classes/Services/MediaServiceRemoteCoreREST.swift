import Foundation
import Combine
import WordPressCore
import WordPressShared
import WordPressAPI
import WordPressKit

/// A `MediaServiceRemote` implementation that uses the WordPress core REST API (`/wp-json/wp/v2/media`).
class MediaServiceRemoteCoreREST: NSObject, MediaServiceRemote {
    let client: WordPressClient

    init(client: WordPressClient) {
        self.client = client
    }

    func getMediaWithID(_ mediaID: NSNumber, success: ((RemoteMedia?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                let media = try await client.api.media.retrieveWithEditContext(mediaId: mediaID.int64Value).data
                success?(RemoteMedia(media: media))
            } catch {
                failure?(error)
            }
        }
    }

    func uploadMedia(
        _ media: RemoteMedia,
        progress progressPtr: AutoreleasingUnsafeMutablePointer<Progress?>?,
        success: ((RemoteMedia?) -> Void)?,
        failure: (((any Error)?) -> Void)?
    ) {
        guard let localURL = media.localURL else {
            wpAssertionFailure("local url missing in the media")
            failure?(URLError(.fileDoesNotExist))
            return
        }

        // Set up a `Progress` instance that are updated from the main thread, which is a behaviour that other parts of the app rely on.
        let totalUnit: Int64 = 100
        let mainThreadProgress = Progress(totalUnitCount: totalUnit)
        progressPtr?.pointee = mainThreadProgress

        Task { @MainActor in
            do {
                let progress = Progress.discreteProgress(totalUnitCount: totalUnit)
                let cancellable = progress
                    .publisher(for: \.fractionCompleted, options: .new)
                    .map { Int64($0 * Double(totalUnit)) }
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.completedUnitCount, on: mainThreadProgress)
                defer { cancellable.cancel() }

                let media = try await client.api.uploadMedia(params: .init(media: media), fromLocalFileURL: localURL, fulfilling: progress).data
                success?(.init(media: media))
            } catch {
                failure?(error)
            }
        }
    }

    func update(_ media: RemoteMedia, success: ((RemoteMedia?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        guard let mediaID = media.mediaID else {
            wpAssertionFailure("id missing in the media")
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let media = try await client.api.media.update(mediaId: mediaID.int64Value, params: .init(media: media)).data
                success?(.init(media: media))
            } catch {
                failure?(error)
            }
        }
    }

    func delete(_ media: RemoteMedia, success: (() -> Void)?, failure: (((any Error)?) -> Void)?) {
        guard let mediaID = media.mediaID else {
            wpAssertionFailure("id missing in the media")
            failure?(URLError(.unknown))
            return
        }

        Task { @MainActor in
            do {
                let _ = try await client.api.media.delete(mediaId: mediaID.int64Value)
                success?()
            } catch {
                failure?(error)
            }
        }
    }

    func getMediaLibrary(pageLoad: (([Any]?) -> Void)!, success: (([Any]?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                var all = [RemoteMedia]()
                let sequence = await client.api.media.sequenceWithEditContext(params: .init())
                for try await element in sequence {
                    let page = element.map { RemoteMedia(media: $0) }
                    all.append(contentsOf: page)
                    pageLoad(page)
                }
                success?(all)
            } catch {
                failure?(error)
            }
        }
    }

    func getMediaLibraryCount(forType mediaType: String?, withSuccess success: ((Int) -> Void)?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                let response = try await client.api.media.listWithEditContext(params: .init(mimeType: mediaType))
                success?(Int(response.headerMap.wpTotal() ?? 0))
            } catch {
                failure?(error)
            }
        }
    }

    func getMetadataFromVideoPressID(
        _ videoPressID: String!,
        isSitePrivate: Bool,
        success: ((WordPressKit.RemoteVideoPressVideo?) -> Void)?,
        failure: (((any Error)?) -> Void)?
    ) {
        // ⚠️ The endpoint is not available in WordPress core.
        failure?(URLError(.unsupportedURL))
    }

    func getVideoPressToken(_ videoPressID: String!, success: ((String?) -> Void)?, failure: (((any Error)?) -> Void)?) {
        // ⚠️ The endpoint is not available in WordPress core.
        failure?(URLError(.unsupportedURL))
    }
}

private extension RemoteMedia {
    convenience init(media: MediaWithEditContext) {
        self.init()

        self.mediaID = NSNumber(value: media.id)
        self.url = URL(string: media.sourceUrl)
        self.guid = media.guid.raw.flatMap(URL.init(string:))
        self.date = media.dateGmt
        self.postID = media.postId.map { NSNumber(value: $0) }
        self.mimeType = media.mimeType
        self.extension = URL(string: media.sourceUrl)?.pathExtension
        self.title = media.title.raw
        self.caption = media.caption.raw
        self.descriptionText = media.description.raw
        self.alt = media.altText

        switch media.mediaDetails.parseAsMimeType(mimeType: media.mimeType) {
        case let .audio(audio):
            self.length = NSNumber(value: audio.length)
        case let .image(image):
            self.width = NSNumber(value: image.width)
            self.height = NSNumber(value: image.height)
            self.remoteThumbnailURL = image.sizes?["thumbnail"]?.sourceUrl
            self.mediumURL = (image.sizes?["medium"]?.sourceUrl).flatMap(URL.init(string:))
            self.largeURL = (image.sizes?["large"]?.sourceUrl).flatMap(URL.init(string:))
        case let .video(video):
            self.width = NSNumber(value: video.width)
            self.height = NSNumber(value: video.height)
            self.length = NSNumber(value: video.length)
        case .none, .document:
            break
        }

        self.localURL = nil
        self.videopressGUID = nil
        self.shortcode = nil
    }
}

private extension MediaCreateParams {
    init(media: RemoteMedia) {
        self.init(
            date: nil,
            dateGmt: media.date,
            slug: nil,
            status: nil,
            title: media.title,
            author: nil,
            commentStatus: nil,
            pingStatus: nil,
            template: nil,
            altText: media.alt,
            caption: media.caption,
            description: media.descriptionText,
            postId: media.postID?.int64Value
        )
    }
}

private extension MediaUpdateParams {
    init(media: RemoteMedia) {
        self.init(
            date: nil,
            dateGmt: media.date,
            slug: nil,
            status: nil,
            title: media.title,
            author: nil,
            commentStatus: nil,
            pingStatus: nil,
            template: nil,
            altText: media.alt,
            caption: media.caption,
            description: media.descriptionText,
            postId: media.postID?.int64Value
        )
    }
}

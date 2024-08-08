import Foundation
import CoreServices
import Gutenberg
import MediaEditor

class GutenbergMediaInserterHelper: NSObject {
    fileprivate let post: AbstractPost
    fileprivate let gutenberg: Gutenberg
    fileprivate let mediaCoordinator = MediaCoordinator.shared
    fileprivate var mediaObserverReceipt: UUID?

    /// Method of selecting media for upload, used for analytics
    ///
    fileprivate var mediaSelectionMethod: MediaSelectionMethod = .none

    init(post: AbstractPost, gutenberg: Gutenberg) {
        self.post = post
        self.gutenberg = gutenberg
        super.init()
        self.registerMediaObserver()
    }

    deinit {
        self.unregisterMediaObserver()
    }

    func insertFromSiteMediaLibrary(media: [Media], callback: @escaping MediaPickerDidPickMediaCallback) {
        let formattedMedia = media.map { item in
            var metadata: [String: String] = [:]
            if let videopressGUID = item.videopressGUID {
                metadata["videopressGUID"] = videopressGUID
            }
            return MediaInfo(id: item.mediaID?.int32Value, url: item.remoteURL, type: item.mediaTypeString, caption: item.caption, title: item.filename, alt: item.alt, metadata: metadata)
        }
        callback(formattedMedia)
    }

    func insertFromDevice(_ selection: [Any], callback: @escaping MediaPickerDidPickMediaCallback) {
        if let providers = selection as? [NSItemProvider] {
            insertItemProviders(providers, callback: callback)
        } else {
            callback(nil)
        }
    }

    private func insertItemProviders(_ providers: [NSItemProvider], callback: @escaping MediaPickerDidPickMediaCallback) {
        let media: [MediaInfo] = providers.compactMap {
            // WARNING: Media is a CoreData entity and has to be thread-confined
            guard let media = insert(exportableAsset: $0, source: .deviceLibrary) else {
                return nil
            }
            // Gutenberg fails to add an image if the preview `url` is `nil`. But
            // it doesn't need to point anywhere. The placeholder gets displayed
            // as soon as `MediaImportService` generated it (see `MediaState.thumbnailReady`).
            // This way we, dramatically cut CPU and especially memory usage.
            let previewURL = URL.Helpers.temporaryFile(named: "\(media.gutenbergUploadID)")
            return MediaInfo(id: media.gutenbergUploadID, url: previewURL.absoluteString, type: media.mediaTypeString)
        }
        callback(media)
    }

    func insertFromDevice(url: URL, callback: @escaping MediaPickerDidPickMediaCallback, source: MediaSource = .otherApps) {
        guard let media = insert(exportableAsset: url as NSURL, source: source) else {
            callback([])
            return
        }
        let mediaUploadID = media.gutenbergUploadID
        callback([MediaInfo(id: mediaUploadID, url: url.absoluteString, type: media.mediaTypeString)])
    }

    func insertFromImage(image: UIImage, callback: @escaping MediaPickerDidPickMediaCallback, source: MediaSource = .deviceLibrary) {
        guard let media = insert(exportableAsset: image, source: source) else {
            callback([])
            return
        }
        let mediaUploadID = media.gutenbergUploadID

        let url = URL.Helpers.temporaryFile(named: "\(mediaUploadID).jpg")

        do {
            try image.writeJPEGToURL(url)
            callback([MediaInfo(id: mediaUploadID, url: url.absoluteString, type: media.mediaTypeString)])
        } catch {
            callback([MediaInfo(id: mediaUploadID, url: nil, type: media.mediaTypeString)])
            return
        }
    }

    func syncUploads() {
        for media in post.media {
            if media.remoteStatus == .failed {
                gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: .uploading, progress: 0, url: media.absoluteThumbnailLocalURL, serverID: nil)
                let finalState: Gutenberg.MediaUploadState = ReachabilityUtils.isInternetReachable() ? .failed : .paused
                if finalState == .paused {
                    trackPausedMediaOf(media)
                }
                gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: finalState, progress: 0, url: nil, serverID: nil)
            }
        }
    }

    func mediaFor(uploadID: Int32) -> Media? {
        for media in post.media {
            if media.gutenbergUploadID == uploadID {
                return media
            }
        }
        return nil
    }

    func isUploadingMedia() -> Bool {
        return mediaCoordinator.isUploadingMedia(for: post)
    }

    func cancelUploadOf(media: Media) {
        mediaCoordinator.cancelUploadAndDeleteMedia(media)
        gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: .reset, progress: 0, url: nil, serverID: nil)
    }

    func retryFailedMediaUploads(automatedRetry: Bool = false) {
        _ = mediaCoordinator.uploadMedia(for: post, automatedRetry: automatedRetry)
    }

    func insert(exportableAsset: ExportableAsset, source: MediaSource) -> Media? {
        let info = MediaAnalyticsInfo(origin: .editor(source), selectionMethod: mediaSelectionMethod)
        return mediaCoordinator.addMedia(from: exportableAsset, to: self.post, analyticsInfo: info)
    }

    /// Method to be used to refresh the status of all media associated with the post.
    /// this method should be called when opening a post to make sure every media block has the correct visual status.
    func refreshMediaStatus() {
        for media in post.media {
            switch media.remoteStatus {
            case .processing:
                mediaObserver(media: media, state: .processing)
            case .pushing:
                var progressValue = 0.5
                if let progress = mediaCoordinator.progress(for: media) {
                    progressValue = progress.fractionCompleted
                }
                mediaObserver(media: media, state: .progress(value: progressValue))
            case .failed:
                if let error = media.error as NSError? {
                    mediaObserver(media: media, state: .failed(error: error))
                }
            default:
                break
            }
        }
    }

    private func registerMediaObserver() {
        mediaObserverReceipt =  mediaCoordinator.addObserver({ [weak self](media, state) in
            self?.mediaObserver(media: media, state: state)
            }, forMediaFor: post)
    }

    private func unregisterMediaObserver() {
        if let receipt = mediaObserverReceipt {
            mediaCoordinator.removeObserver(withUUID: receipt)
        }
    }

    private func mediaObserver(media: Media, state: MediaCoordinator.MediaState) {
        let mediaUploadID = media.gutenbergUploadID
        switch state {
        case .processing:
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .uploading, progress: 0, url: nil, serverID: nil)
        case .thumbnailReady(let url):
            gutenberg.mediaUploadUpdate(id: mediaUploadID, url: url)
            break
        case .uploading:
            break
        case .ended:
            var currentURL = media.remoteURL

            if media.remoteLargeURL != nil {
                currentURL = media.remoteLargeURL
            } else if media.remoteMediumURL != nil {
                currentURL = media.remoteMediumURL
            }

            guard let urlString = currentURL, let url = URL(string: urlString), let mediaServerID = media.mediaID?.int32Value else {
                break
            }
            switch media.mediaType {
            case .video:
                // Fetch metadata when is a VideoPress video
                if media.videopressGUID != nil {
                    EditorMediaUtility.fetchVideoPressMetadata(for: media, in: post) { [weak self] (result) in
                        guard let strongSelf = self else {
                            return
                        }
                        switch result {
                        case .failure:
                            strongSelf.gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .failed, progress: 0, url: nil, serverID: nil)
                        case .success(let metadata):
                            strongSelf.gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .succeeded, progress: 1, url: metadata.originalURL, serverID: mediaServerID, metadata: metadata.asDictionary())
                        }
                    }
                } else {
                    guard let remoteURLString = media.remoteURL, let remoteURL = URL(string: remoteURLString) else {
                        gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .failed, progress: 0, url: nil, serverID: nil)
                        return
                    }
                    gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .succeeded, progress: 1, url: remoteURL, serverID: mediaServerID)
                }
            default:
                gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .succeeded, progress: 1, url: url, serverID: mediaServerID)
            }
        case .failed(let error):
            switch error.code {
            case NSURLErrorCancelled:
                gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .reset, progress: 0, url: nil, serverID: nil)
            case NSURLErrorNetworkConnectionLost: fallthrough
            case NSURLErrorNotConnectedToInternet: fallthrough
            case NSURLErrorTimedOut where !ReachabilityUtils.isInternetReachable():
                trackPausedMediaOf(media)
                // The progress value passed is ignored by the editor, allowing the UI to retain the last known progress before pausing
                gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .paused, progress: 0, url: nil, serverID: nil)
            default:
                gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .failed, progress: 0, url: nil, serverID: nil)
            }
        case .progress(let value):
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .uploading, progress: Float(value), url: nil, serverID: nil)
        case .cancelled:
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .reset, progress: 0, url: nil, serverID: nil)
        }
    }

    private func trackPausedMediaOf(_ media: Media) {
        let info = MediaAnalyticsInfo(origin: .editor(.none), selectionMethod: mediaSelectionMethod)
        mediaCoordinator.trackPausedUploadOf(media, analyticsInfo: info)
    }
}

extension Media {
    var gutenbergUploadID: Int32 {
        return Int32(truncatingIfNeeded: objectID.uriRepresentation().absoluteString.hash)
    }
}

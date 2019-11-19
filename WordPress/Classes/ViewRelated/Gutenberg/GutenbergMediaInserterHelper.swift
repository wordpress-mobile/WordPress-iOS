import Foundation
import CoreServices
import WPMediaPicker
import Gutenberg

class GutenbergMediaInserterHelper: NSObject {
    fileprivate let post: AbstractPost
    fileprivate let gutenberg: Gutenberg
    fileprivate let mediaCoordinator = MediaCoordinator.shared
    fileprivate var mediaObserverReceipt: UUID?

    /// Method of selecting media for upload, used for analytics
    ///
    fileprivate var mediaSelectionMethod: MediaSelectionMethod = .none

    var didPickMediaCallback: GutenbergMediaPickerHelperCallback?

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
            return MediaInfo(id: item.mediaID?.int32Value, url: item.remoteURL, type: item.mediaTypeString)
        }
        callback(formattedMedia)
    }

    func insertFromDevice(assets: [PHAsset], callback: @escaping MediaPickerDidPickMediaCallback) {
        var mediaCollection: [MediaInfo] = []
        let group = DispatchGroup()
        assets.forEach { asset in
            group.enter()
            insertFromDevice(asset: asset, callback: { media in
                guard let media = media,
                let selectedMedia = media.first else {
                    group.leave()
                    return
                }
                mediaCollection.append(selectedMedia)
                group.leave()
            })
        }

        group.notify(queue: .main) {
            callback(mediaCollection)
        }
    }

    func insertFromDevice(asset: PHAsset, callback: @escaping MediaPickerDidPickMediaCallback) {
        guard let media = insert(exportableAsset: asset, source: .deviceLibrary) else {
            callback([])
            return
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.version = .current
        options.resizeMode = .fast
        let mediaUploadID = media.gutenbergUploadID
        // Getting a quick thumbnail of the asset to display while the image is being exported and uploaded.
        PHImageManager.default().requestImage(for: asset, targetSize: asset.pixelSize(), contentMode: .default, options: options) { (image, info) in
            guard let thumbImage = image, let resizedImage = thumbImage.resizedImage(asset.pixelSize(), interpolationQuality: CGInterpolationQuality.low) else {
                callback([MediaInfo(id: mediaUploadID, url: nil, type: media.mediaTypeString)])
                return
            }
            let filePath = NSTemporaryDirectory() + "\(mediaUploadID).jpg"
            let url = URL(fileURLWithPath: filePath)
            do {
                try resizedImage.writeJPEGToURL(url)
                callback([MediaInfo(id: mediaUploadID, url: url.absoluteString, type: media.mediaTypeString)])
            } catch {
                callback([MediaInfo(id: mediaUploadID, url: nil, type: media.mediaTypeString)])
                return
            }
        }
    }

    func insertFromDevice(url: URL, callback: @escaping MediaPickerDidPickMediaCallback) {
        guard let media = insert(exportableAsset: url as NSURL, source: .otherApps) else {
            callback([])
            return
        }
        let mediaUploadID = media.gutenbergUploadID
        callback([MediaInfo(id: mediaUploadID, url: url.absoluteString, type: media.mediaTypeString)])
    }

    func syncUploads() {
        if mediaObserverReceipt != nil {
            registerMediaObserver()
        }
        for media in post.media {
            if media.remoteStatus == .failed {
                gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: .uploading, progress: 0, url: media.absoluteThumbnailLocalURL, serverID: nil)
                gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: .failed, progress: 0, url: nil, serverID: nil)
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

    func cancelUploadOfAllMedia() {
        mediaCoordinator.cancelUploadOfAllMedia(for: post)
    }

    func cancelUploadOf(media: Media) {
        mediaCoordinator.cancelUploadAndDeleteMedia(media)
        gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: .reset, progress: 0, url: nil, serverID: nil)
    }

    func retryUploadOf(media: Media) {
        mediaCoordinator.retryMedia(media)
    }

    func hasFailedMedia() -> Bool {
        return mediaCoordinator.hasFailedMedia(for: post)
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
        // Make sure gutenberg is loaded before seding events to it.
        guard gutenberg.isLoaded else {
            return
        }
        let mediaUploadID = media.gutenbergUploadID
        switch state {
        case .processing:
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .uploading, progress: 0, url: nil, serverID: nil)
        case .thumbnailReady(let url):
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .uploading, progress: 0.20, url: url, serverID: nil)
            break
        case .uploading:
            break
        case .ended:
            guard let urlString = media.remoteURL, let url = URL(string: urlString), let mediaServerID = media.mediaID?.int32Value else {
                break
            }
            switch media.mediaType {
            case .image:
                gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .succeeded, progress: 1, url: url, serverID: mediaServerID)
            case .video:
                EditorMediaUtility.fetchRemoteVideoURL(for: media, in: post) { [weak self] (result) in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .error:
                        strongSelf.gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .failed, progress: 0, url: nil, serverID: nil)
                    case .success(let value):
                        strongSelf.gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .succeeded, progress: 1, url: value.videoURL, serverID: mediaServerID)
                    }
                }
            default:
                break
            }
        case .failed(let error):
            if error.code == NSURLErrorCancelled {
                gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .reset, progress: 0, url: nil, serverID: nil)
                return
            }
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .failed, progress: 0, url: nil, serverID: nil)
        case .progress(let value):
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .uploading, progress: Float(value), url: nil, serverID: nil)
        }
    }
}

extension Media {
    var gutenbergUploadID: Int32 {
        return Int32(truncatingIfNeeded: objectID.uriRepresentation().absoluteString.hash)
    }
}

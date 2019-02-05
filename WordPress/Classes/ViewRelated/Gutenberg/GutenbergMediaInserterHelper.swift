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

    func insertFromSiteMediaLibrary(media: Media, callback: @escaping MediaPickerDidPickMediaCallback) {
        callback(media.mediaID?.int32Value, media.remoteURL)
    }

    func insertFromDevice(asset: PHAsset, callback: @escaping MediaPickerDidPickMediaCallback) {
        let media = insert(exportableAsset: asset, source: .deviceLibrary)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.version = .current
        options.resizeMode = .fast
        let mediaUploadID = media.gutenbergUploadID
        // Getting a quick thumbnail of the asset to display while the image is being exported and uploaded.
        PHImageManager.default().requestImage(for: asset, targetSize: asset.pixelSize(), contentMode: .default, options: options) { (image, info) in
            guard let thumbImage = image, let resizedImage = thumbImage.resizedImage(asset.pixelSize(), interpolationQuality: CGInterpolationQuality.low) else {
                callback(mediaUploadID, nil)
                return
            }
            let filePath = NSTemporaryDirectory() + UUID().uuidString + ".jpg"
            let url = URL(fileURLWithPath: filePath)
            do {
                try resizedImage.writeJPEGToURL(url)
                callback(mediaUploadID, url.absoluteString)
            } catch {
                callback(mediaUploadID, nil)
                return
            }
        }

    }

    func syncUploads() {
        if mediaObserverReceipt != nil {
            registerMediaObserver()
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

    func cancelUploadOf(media: Media) {
        mediaCoordinator.cancelUpload(of: media)
        gutenberg.mediaUploadUpdate(id: media.gutenbergUploadID, state: .reset, progress: 0, url: nil, serverID: nil)
    }

    func retryUploadOf(media: Media) {
        mediaCoordinator.retryMedia(media)
    }

    private func insert(exportableAsset: ExportableAsset, source: MediaSource) -> Media {
        switch exportableAsset.assetMediaType {
        case .image:
            break
        case .video:
            break
        default:
            break
        }

        let info = MediaAnalyticsInfo(origin: .editor(source), selectionMethod: mediaSelectionMethod)
        let media = mediaCoordinator.addMedia(from: exportableAsset, to: self.post, analyticsInfo: info)
        return media
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
        case .thumbnailReady:
            break
        case .uploading:
            break
        case .ended:
            guard let urlString = media.remoteURL, let url = URL(string: urlString), let mediaServerID = media.mediaID?.int32Value else {
                break
            }
            gutenberg.mediaUploadUpdate(id: mediaUploadID, state: .succeeded, progress: 1, url: url, serverID: mediaServerID)
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

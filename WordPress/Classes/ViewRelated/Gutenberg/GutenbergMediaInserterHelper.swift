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
        callback(media.mediaID?.intValue, media.remoteURL)
    }

    func insertFromDevice(asset: PHAsset, callback: @escaping MediaPickerDidPickMediaToUploadCallback) {
        let media = insert(exportableAsset: asset, source: .deviceLibrary)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.version = .current
        // Getting a quick thumbnail of the asset to display while the image is being exported and uploaded.
        PHImageManager.default().requestImage(for: asset, targetSize: asset.pixelSize(), contentMode: .default, options: options) { (image, info) in
            guard let thumbImage = image else {
                callback(media.uploadID, nil)
                return
            }
            let filePath = NSTemporaryDirectory() + UUID().uuidString + ".jpg"
            let url = URL(fileURLWithPath: filePath)
            do {
                try thumbImage.writeJPEGToURL(url)
                callback(media.uploadID, url.absoluteString)
            } catch {
                callback(media.uploadID, nil)
                return
            }
        }

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
        switch state {
        case .processing:
            DDLogInfo("Creating media")
        case .thumbnailReady(let url):
            gutenberg.mediaUploadUpdate(id: media.uploadID, state: .uploading, progress: 0.1, url: url, serverID: nil)
        case .uploading:
            gutenberg.mediaUploadUpdate(id: media.uploadID, state: .uploading, progress: 0.1, url: nil, serverID: nil)
        case .ended:
            guard let urlString = media.remoteURL, let url = URL(string: urlString), let mediaServerID = media.mediaID?.intValue else {
                break
            }
            gutenberg.mediaUploadUpdate(id: media.uploadID, state: .succeeded, progress: 1, url: url, serverID: mediaServerID)
        case .failed:
            gutenberg.mediaUploadUpdate(id: media.uploadID, state: .failed, progress: 0, url: nil, serverID: nil)
        case .progress(let value):
            gutenberg.mediaUploadUpdate(id: media.uploadID, state: .uploading, progress: Float(value), url: nil, serverID: nil)
        }
    }
}

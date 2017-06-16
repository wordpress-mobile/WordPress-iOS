import Foundation

/// Media Progress Coordinator Delegate comunicates changes on media uploading progress.
///
@objc public protocol MediaProgressCoordinatorDelegate: class {

    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange progress: Float)
    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator)
    func mediaProgressCoordinatorDidFinishUpload(_ mediaProgressCoordinator: MediaProgressCoordinator)
}

/// Media Progress Coordinator allow the tracking of multiple media progress uploads.
///
public class MediaProgressCoordinator: NSObject {

    enum ProgressMediaKeys: String {
        case mediaID = "mediaID"
        case error = "mediaError"
        case mediaObject = "mediaObject"
    }

    public weak var delegate: MediaProgressCoordinatorDelegate?

    private(set) var mediaUploadingProgress: Progress?

    private(set) lazy var mediaUploading: [String:Progress] = {
        return [String: Progress]()
    }()

    private var mediaUploadingProgressObserverContext: String = "mediaUploadingProgressObserverContext"

    deinit {
        mediaUploadingProgress?.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
    }

    func finishOneItem() {
        guard let mediaUploadingProgress = mediaUploadingProgress else {
            return
        }

        mediaUploadingProgress.completedUnitCount += 1
    }

    func track(numberOfItems count: Int) {
        if let mediaUploadingProgress = self.mediaUploadingProgress, !isRunning {
            mediaUploadingProgress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            self.mediaUploadingProgress = nil
        }

        if self.mediaUploadingProgress == nil {
            self.mediaUploadingProgress = Progress.discreteProgress(totalUnitCount: 0)
            self.mediaUploadingProgress?.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options:[.new], context:&mediaUploadingProgressObserverContext)

            delegate?.mediaProgressCoordinatorDidStartUploading(self)
        }

        self.mediaUploadingProgress?.totalUnitCount += Int64(count)
    }

    func track(progress: Progress, ofObject object: Any, withMediaID mediaID: String) {
        progress.setUserInfoObject(mediaID, forKey: ProgressUserInfoKey(ProgressMediaKeys.mediaID.rawValue))
        progress.setUserInfoObject(object, forKey: ProgressUserInfoKey(ProgressMediaKeys.mediaObject.rawValue))
        mediaUploadingProgress?.addChild(progress, withPendingUnitCount: 1)
        mediaUploading[mediaID] = progress
    }

    func attach(error: NSError, toMediaID mediaID: String) {
        guard let progress = mediaUploading[mediaID] else {
            return
        }
        progress.setUserInfoObject(error, forKey: ProgressUserInfoKey(ProgressMediaKeys.error.rawValue))
    }

    func error(forMediaID mediaID: String) -> NSError? {
        guard let progress = mediaUploading[mediaID],
            let error = progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.error.rawValue)] as? NSError
            else {
                return nil
        }

        return error
    }

    func object(forMediaID mediaID: String) -> Any? {
        guard let progress = mediaUploading[mediaID],
            let object = progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.mediaObject.rawValue)]
            else {
                return nil
        }

        return object
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            context == &mediaUploadingProgressObserverContext,
            keyPath == #keyPath(Progress.fractionCompleted)
            else {
                super.observeValue(forKeyPath: keyPath,
                                   of: object,
                                   change: change,
                                   context: context)
                return
        }

        DispatchQueue.main.async {
            self.refreshMediaProgress()
        }
    }

    var totalProgress: Float {
        var value = Float(0)
        if let progress = mediaUploadingProgress {
            value = Float(progress.fractionCompleted)
        }
        return value
    }

    private func refreshMediaProgress() {

        delegate?.mediaProgressCoordinator(self, progressDidChange: totalProgress)

        if !isRunning {
            delegate?.mediaProgressCoordinatorDidFinishUpload(self)
        }
    }

    func isMediaUploading(mediaID: String) -> Bool {
        if let mediaProgress = mediaUploading[mediaID],
            mediaProgress.completedUnitCount < mediaProgress.totalUnitCount {
            return true
        }
        return false
    }

    var isRunning: Bool {
        guard let progress = mediaUploadingProgress else {
            return false
        }

        if progress.isCancelled {
            return false
        }

        if mediaUploading.isEmpty {
            return progress.completedUnitCount < progress.totalUnitCount
        }

        for progress in mediaUploading.values {
            if !progress.isCancelled && (progress.totalUnitCount != progress.completedUnitCount) {
                return true
            }
        }
        return false
    }

    var hasFailedMedia: Bool {
        for progress in mediaUploading.values {
            if !progress.isCancelled && progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.error.rawValue)] != nil {
                return true
            }
        }
        return false
    }

    func cancelAndStopTrack(of mediaID: String) {
        guard let mediaProgress = mediaUploading[mediaID] else {
            return
        }
        if mediaProgress.completedUnitCount < mediaProgress.totalUnitCount {
            mediaProgress.cancel()
        }
        mediaUploading.removeValue(forKey: mediaID)
    }

    var allCancelledIDs: [String] {
        var mediaIDs = [String]()
        for (key, progress) in mediaUploading {
            if progress.isCancelled {
                mediaIDs.append(key)
            }
        }
        return mediaIDs
    }

    var pendingUploadIDs: [String] {
        var mediaIDs = [String]()
        for (key, progress) in mediaUploading {
            if !progress.isCancelled && progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.error.rawValue)] == nil {
                mediaIDs.append(key)
            }
        }
        return mediaIDs
    }

    func cancelAllPendingUploads() {
        let pendingUploadIds = mediaUploading.keys

        for mediaID in pendingUploadIds {
            cancelAndStopTrack(of: mediaID)
        }

        mediaUploadingProgress?.cancel()
    }

    func stopTrackingOfAllUploads() {
        if let mediaUploadingProgress = self.mediaUploadingProgress, !isRunning {
            mediaUploadingProgress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            self.mediaUploadingProgress = nil
        }
        mediaUploading.removeAll()
    }

    var failedMediaIDs: [String] {
        var failedMediaIDs = [String]()
        for (key, progress) in mediaUploading {
            if !progress.isCancelled && progress.userInfo[ProgressUserInfoKey(ProgressMediaKeys.error.rawValue)] != nil {
                failedMediaIDs.append(key)
            }
        }
        return failedMediaIDs
    }

    func stopTrackingAllFailedMedia() {
        for key in failedMediaIDs {
            mediaUploading.removeValue(forKey: key)
        }
    }

    func progress(forMediaID mediaID: String) -> Progress? {
        return mediaUploading[mediaID]
    }
}

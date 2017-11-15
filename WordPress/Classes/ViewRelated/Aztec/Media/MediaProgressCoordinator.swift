import Foundation

/// Media Progress Coordinator Delegate comunicates changes on media uploading progress.
///
@objc public protocol MediaProgressCoordinatorDelegate: class {

    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange progress: Float)
    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator)
    func mediaProgressCoordinatorDidFinishUpload(_ mediaProgressCoordinator: MediaProgressCoordinator)
}

extension ProgressUserInfoKey {
    static let mediaID = ProgressUserInfoKey("mediaID")
    static let mediaError = ProgressUserInfoKey("mediaError")
    static let mediaObject = ProgressUserInfoKey("mediaObject")
}
/// Media Progress Coordinator allow the tracking of multiple media progress uploads.
///
public class MediaProgressCoordinator: NSObject {

    @objc public weak var delegate: MediaProgressCoordinatorDelegate?

    @objc private(set) var mediaUploadingProgress: Progress?

    @objc private(set) lazy var mediaUploading: [String: Progress] = {
        return [String: Progress]()
    }()

    private var mediaUploadingProgressObserverContext: String = "mediaUploadingProgressObserverContext"

    deinit {
        mediaUploadingProgress?.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
    }

    /// Setup the coordinator to track the provided number of tasks
    ///
    /// - Parameter count: the number of tasks that need to be tracked
    @objc func track(numberOfItems count: Int) {
        if let mediaUploadingProgress = self.mediaUploadingProgress, !isRunning {
            mediaUploadingProgress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            self.mediaUploadingProgress = nil
        }

        if self.mediaUploadingProgress == nil {
            self.mediaUploadingProgress = Progress.discreteProgress(totalUnitCount: 0)
            self.mediaUploadingProgress?.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.new], context: &mediaUploadingProgressObserverContext)

            delegate?.mediaProgressCoordinatorDidStartUploading(self)
        }

        self.mediaUploadingProgress?.totalUnitCount += Int64(count)
    }

    /// Start the tracking of a task that is represented by the provided progress and is associated to an object with the provided mediaID.
    ///
    /// - Parameters:
    ///   - progress: the object that tracks the progress
    ///   - object: the associated object.
    ///   - mediaID: the unique taskID
    @objc func track(progress: Progress, ofObject object: Any, withMediaID mediaID: String) {
        progress.setUserInfoObject(mediaID, forKey: .mediaID)
        progress.setUserInfoObject(object, forKey: .mediaObject)
        mediaUploadingProgress?.addChild(progress, withPendingUnitCount: 1)
        mediaUploading[mediaID] = progress
    }

    /// Finish one of the tasks.
    ///
    /// Note: This method is used to advance the completed number of tasks, when the task doesn't have any relevant associated work/progress to be tracked.
    /// For example an already existing media object that is already uploaded to the server.
    @objc func finishOneItem() {
        guard let mediaUploadingProgress = mediaUploadingProgress else {
            return
        }

        mediaUploadingProgress.completedUnitCount += 1
    }

    /// Attach an error to an ongoing media creation/upload task
    ///
    /// - Parameters:
    ///   - error: the error to attach
    ///   - mediaID: the mediaID to attach error
    @objc func attach(error: NSError, toMediaID mediaID: String) {
        guard let progress = mediaUploading[mediaID] else {
            return
        }
        progress.setUserInfoObject(error, forKey: .mediaError)
    }

    // MARK: - Methods to check state of a mediaID process

    /// Return the error, if any, associated to the task with the provided mediaID
    ///
    /// - Parameter mediaID: mediaID to search for error
    /// - Returns: the error value if any
    @objc func error(forMediaID mediaID: String) -> NSError? {
        guard let progress = mediaUploading[mediaID],
            let error = progress.userInfo[.mediaError] as? NSError
            else {
                return nil
        }

        return error
    }

    @objc func object(forMediaID mediaID: String) -> Any? {
        guard let progress = mediaUploading[mediaID],
            let object = progress.userInfo[.mediaObject]
            else {
                return nil
        }

        return object
    }

    @objc var totalProgress: Float {
        var value = Float(0)
        if let progress = mediaUploadingProgress {
            value = Float(progress.fractionCompleted)
        }
        return value
    }

    @objc func progress(forMediaID mediaID: String) -> Progress? {
        return mediaUploading[mediaID]
    }

    @objc func isMediaUploading(mediaID: String) -> Bool {
        if let mediaProgress = mediaUploading[mediaID],
            mediaProgress.completedUnitCount < mediaProgress.totalUnitCount {
            return true
        }
        return false
    }

    /// Returns true if any task is still ongoing
    @objc var isRunning: Bool {
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

    /// Returns true if any of media tasks being tracked have an error associated
    @objc var hasFailedMedia: Bool {
        for progress in mediaUploading.values {
            if !progress.isCancelled && progress.userInfo[.mediaError] != nil {
                return true
            }
        }
        return false
    }

    /// Return a list of media ID that were cancelled
    ///
    @objc var allCancelledIDs: [String] {
        var mediaIDs = [String]()
        for (key, progress) in mediaUploading {
            if progress.isCancelled {
                mediaIDs.append(key)
            }
        }
        return mediaIDs
    }

    /// Return a list of media ID that are still uploading
    ///
    @objc var pendingUploadIDs: [String] {
        var mediaIDs = [String]()
        for (key, progress) in mediaUploading {
            if !progress.isCancelled && progress.userInfo[.mediaError] == nil {
                mediaIDs.append(key)
            }
        }
        return mediaIDs
    }

    /// Returns a list of all media ID that have an error attached
    ///
    @objc var failedMediaIDs: [String] {
        var failedMediaIDs = [String]()
        for (key, progress) in mediaUploading {
            if !progress.isCancelled && progress.userInfo[.mediaError] != nil {
                failedMediaIDs.append(key)
            }
        }
        return failedMediaIDs
    }

    // MARK: - KeyPath observer method for the global progress property
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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

    private func refreshMediaProgress() {

        delegate?.mediaProgressCoordinator(self, progressDidChange: totalProgress)

        if !isRunning {
            delegate?.mediaProgressCoordinatorDidFinishUpload(self)
        }
    }

    // MARK: - Actions

    /// Cancels and stop tracking of progress for a media upload
    ///
    /// - Parameter mediaID: the identifier for the media
    ///
    @objc func cancelAndStopTrack(of mediaID: String) {
        guard let mediaProgress = mediaUploading[mediaID] else {
            return
        }
        if mediaProgress.completedUnitCount < mediaProgress.totalUnitCount {
            mediaProgress.cancel()
        }
        mediaUploading.removeValue(forKey: mediaID)
    }

    /// Cancels all pending uploads and stops tracking the progress of them
    ///
    @objc func cancelAndStopAllPendingUploads() {
        let pendingUploadIds = mediaUploading.keys

        for mediaID in pendingUploadIds {
            cancelAndStopTrack(of: mediaID)
        }

        mediaUploadingProgress?.cancel()
    }

    /// Stop trackings all media uploads and resets the global progress tracking
    ///
    @objc func stopTrackingOfAllUploads() {
        if let mediaUploadingProgress = self.mediaUploadingProgress, !isRunning {
            mediaUploadingProgress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
            self.mediaUploadingProgress = nil
        }
        mediaUploading.removeAll()
    }

    /// Stop tracking of all media uploads that are in failed/error state.
    @objc func stopTrackingAllFailedMedia() {
        for key in failedMediaIDs {
            mediaUploading.removeValue(forKey: key)
        }
    }

}

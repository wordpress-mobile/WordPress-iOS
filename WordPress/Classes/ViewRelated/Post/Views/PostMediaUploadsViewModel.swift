import Foundation
import SwiftUI
import Combine

/// Manages media upload for the given revision of the post.
final class PostMediaUploadsViewModel: ObservableObject {
    private(set) var uploads: [PostMediaUploadItemViewModel]

    @Published private(set) var totalFileSize: Int64 = 0
    @Published private(set) var fractionCompleted = 0.0
    @Published private(set) var completedUploadsCount = 0

    var isCompleted: Bool { uploads.count == completedUploadsCount }

    private let post: AbstractPost
    private let coordinator: MediaCoordinator
    private weak var timer: Timer?
    private var cancellables: [AnyCancellable] = []

    deinit {
        timer?.invalidate()
    }

    init(post: AbstractPost, coordinator: MediaCoordinator = .shared) {
        self.post = post
        self.coordinator = coordinator
        self.uploads = Array(post.media).filter(\.isUploadNeeded).sorted {
            ($0.creationDate ?? .now) < ($1.creationDate ?? .now)
        }.map {
            PostMediaUploadItemViewModel(media: $0, coordinator: coordinator)
        }

        coordinator.uploadMedia(for: post)

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.update()
        }

        post.publisher(for: \.media).sink { [weak self] in
            self?.didUpdateMedia($0)
        }.store(in: &cancellables)
    }

    private func didUpdateMedia(_ media: Set<Media>) {
        let remainingObjectIDs = Set(media.map(\.objectID))
        withAnimation {
            uploads.removeAll { viewModel in
                !remainingObjectIDs.contains(viewModel.id)
            }
        }
    }

    private func update() {
        for upload in uploads {
            upload.update()
        }

        totalFileSize = uploads.map(\.fileSize).reduce(0, +)
        fractionCompleted = uploads.map(\.fractionCompleted).reduce(0, +) / Double(uploads.count)
        completedUploadsCount = uploads.filter(\.isCompleted).count
    }

    func buttonRetryTapped() {
        for upload in uploads {
            upload.retry()
        }
    }
}

/// Manages individual media upload.
final class PostMediaUploadItemViewModel: ObservableObject, Identifiable {
    @Published private(set) var state: State = .uploading

    let media: Media
    private let coordinator: MediaCoordinator

    private var completed: Int64 = 0

    @Published private(set) var thumbnail: UIImage?
    @Published private(set) var title = ""
    @Published private(set) var details = ""

    @Published private(set) var fileSize: Int64 = 0
    @Published private(set) var fractionCompleted = 0.0

    private weak var retryTimer: Timer?

    private var nextRetryDelay: TimeInterval {
        retryDelay = min(32, retryDelay * 1.5)
        return retryDelay
    }
    private var retryDelay: TimeInterval = 8

    var id: NSManagedObjectID { media.objectID }

    var thumbnailAspectRatio: CGFloat {
        guard let width = media.width?.floatValue, width > 0,
              let height = media.height?.floatValue, height > 0 else {
            return 1
        }
        return CGFloat(width / height)
    }

    var thumbnailMaxHeight: CGFloat {
        MediaImageService.isThubmnailSupported(for: media.mediaType) ? 40 : 24
    }

    var isCompleted: Bool {
        if case .uploaded = state { return true }
        return false
    }

    var error: Error? {
        if case .failed(let error) = state { return error }
        return nil
    }

    enum State {
        case uploading
        case failed(Error)
        case uploaded
    }

    deinit {
        retryTimer?.invalidate()
    }

    init(media: Media, coordinator: MediaCoordinator) {
        self.media = media
        self.coordinator = coordinator

        title = media.filename ?? "–"
        update()

        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateReachability), name: .reachabilityChanged, object: nil)
    }

    fileprivate func update() {
        self.state = media.isUploadNeeded ? .uploading : .uploaded
        self.fileSize = media.filesize?.int64Value ?? 0 // Should never be `0`

        if media.remoteStatus == .failed, let error = media.error, MediaCoordinator.isTerminalError(error) {
            self.details = error.localizedDescription
            self.state = .failed(error)
            return // No retry
        }

        if media.remoteStatus == .failed, retryTimer == nil {
            retryTimer = Timer.scheduledTimer(withTimeInterval: nextRetryDelay, repeats: false) { [weak self] _ in self?.retry() }
        }

        if media.isUploadNeeded {
            if let progress = coordinator.progress(for: media),
               let uploadProgress = progress.userInfo[.uploadProgress] as? Progress {
                let completed = Int64(Double(fileSize) * uploadProgress.fractionCompleted)
                self.fractionCompleted = uploadProgress.fractionCompleted
                self.completed = max(completed, self.completed)
            }
            details = Strings.progress(completed: completed, total: fileSize)
        } else {
            fractionCompleted = 1.0
            details = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
    }

    fileprivate func retry() {
        retryTimer?.invalidate()
        retryTimer = nil
        coordinator.retryMedia(media)
    }

    @objc private func didUpdateReachability(_ notification: Foundation.Notification) {
        guard let reachable = notification.userInfo?[Foundation.Notification.reachabilityKey],
              (reachable as? Bool) == true else {
            return
        }
        let code = (media.error as? URLError)?.code
        if code == .notConnectedToInternet || code == .networkConnectionLost {
            retry()
        }
    }

    @MainActor
    func loadThumbnail() async {
        do {
            if MediaImageService.isThubmnailSupported(for: media.mediaType) {
                thumbnail = try await MediaImageService.shared.image(for: media, size: .small)
            } else {
                thumbnail = SiteMediaDocumentInfoViewModel.make(with: media).image
            }
        } catch {
            // Continue showing placeholder
        }
    }

    // MARK: - Actions

    func buttonRetryTapped() {
        retry()
    }

    func buttonCancelTapped() {
        coordinator.cancelUploadAndDeleteMedia(media)
    }
}

private extension Media {
    var isUploadNeeded: Bool {
        mediaID == nil || mediaID?.intValue == 0
    }
}

private enum Strings {
    static func progress(completed: Int64, total: Int64) -> String {
        let format = NSLocalizedString("postMediaUploadStatusView.progress", value: "%1$@ of %2$@", comment: "Shows the upload progress with two preformatted parameters: %1$@ is the placeholder for completed bytes, and %2$@ is the placeholder for total bytes")
        return String(format: format, ByteCountFormatter.string(fromByteCount: completed, countStyle: .file), ByteCountFormatter.string(fromByteCount: total, countStyle: .file))
    }
}

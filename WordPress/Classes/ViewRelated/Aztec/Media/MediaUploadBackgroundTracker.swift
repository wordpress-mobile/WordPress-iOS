import Foundation
import BackgroundTasks
import Combine
import WordPressShared

// This protocol is used to hide the `@available(iOS 26.0, *)` check.
protocol MediaUploadBackgroundTracker {

    func track(progress: Progress, media: TaggedManagedObjectID<Media>) async

}

func mediaUploadBackgroundTracker() -> MediaUploadBackgroundTracker? {
    if #available(iOS 26.0, *) {
        ConcreteMediaUploadBackgroundTracker.shared
    } else {
        nil
    }
}

@available(iOS 26.0, *)
/// Utilize `BGContinuedProcessingTask` to show the uploading media activity.
private actor ConcreteMediaUploadBackgroundTracker: MediaUploadBackgroundTracker {
    struct Item {
        // Please note: all media query needs to be done in the main context, due to the current upload media implementation.
        var media: TaggedManagedObjectID<Media>
        var progress: Progress
    }

    enum BGTaskState {
        struct Accepted {
            let task: BGContinuedProcessingTask
            var items = [Item]()
            var observers: [AnyCancellable] = []

            init(task: BGContinuedProcessingTask) {
                self.task = task
            }
        }

        // No uploading. No `BGContinuedProcessingTask`.
        case idle
        // Waiting for the OS to response to the creating `BGContinuedProcessingTask` request.
        case pending([Item])
        // OS has created a `BGContinuedProcessingTask` instance.
        case accepted(Accepted)
    }

    // Since this type works with `BGTaskScheduler.shared`, it only makes sense for the type to also be a singleton.
    static let shared = ConcreteMediaUploadBackgroundTracker()

    // We only use one `BGContinuedProcessingTask` for all uploads. When adding new media during uploading, the new ones
    // will be added to the existing task.
    private let taskId: String

    // State transtion: idle -> pending -> accepted -> [accepted...] -> idle.
    private var state: BGTaskState = .idle

    private var coreDataChangesObserver: NSObjectProtocol?

    private init() {
        let taskId = Bundle.main.bundleIdentifier! + ".mediaUpload"

        wpAssert(
            (Bundle.main.infoDictionary?["BGTaskSchedulerPermittedIdentifiers"] as? [String])?.contains(taskId) == true,
            "media upload task id not found in the Info.plist"
        )

        self.taskId = taskId
        BGTaskScheduler.shared.register(forTaskWithIdentifier: self.taskId, using: nil) { [weak self] task in
            guard let task = task as? BGContinuedProcessingTask else {
                wpAssertionFailure("Unexpected task instance")
                return
            }

            Task {
                await self?.taskCreated(task)
            }
        }

    }

    func track(progress: Progress, media: TaggedManagedObjectID<Media>) async {
        observeCoreDataChanges()

        let item = Item(media: media, progress: progress)
        switch state {
        case .idle:
            state = .pending([item])

            let request = BGContinuedProcessingTaskRequest(identifier: taskId, title: Strings.uploadingMediaTitle, subtitle: "")
            request.strategy = .queue
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                DDLogError("Failed to submit a background task: \(error)")
            }
        case var .pending(items):
            items.removeAll {
                $0.media == media
            }
            items.append(item)
            self.state = .pending(items)
        case var .accepted(accepted):
            observe(item, accepted: &accepted)
            self.state = .accepted(accepted)
        }
    }

    private func observeCoreDataChanges() {
        guard coreDataChangesObserver == nil else { return }

        coreDataChangesObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: ContextManager.shared.mainContext,
            queue: .main
        ) { [weak self] notification in
            let deleted = notification.userInfo?[NSManagedObjectContext.NotificationKey.deletedObjects.rawValue] as? Set<NSManagedObject> ?? []

            var mediaObjectIDs = Set<TaggedManagedObjectID<Media>>()
            for object in deleted {
                if let media = object as? Media {
                    mediaObjectIDs.insert(TaggedManagedObjectID(media))
                }
            }

            if !mediaObjectIDs.isEmpty {
                Task {
                    await self?.handleMediaObjectsUpdates(updated: mediaObjectIDs)
                }
            }
        }
    }

    private func taskCreated(_ task: BGContinuedProcessingTask) {
        task.progress.totalUnitCount = 100
        task.expirationHandler = { [weak self] in
            Task {
                await self?.handleExpiration()
            }
        }

        var accepted = BGTaskState.Accepted(task: task)
        switch state {
        case .idle, .accepted:
            wpAssertionFailure("Unexpected background task state")
        case let .pending(items):
            for item in items {
                observe(item, accepted: &accepted)
            }
        }

        self.state = .accepted(accepted)
    }

    private func observe(_ item: Item, accepted: inout BGTaskState.Accepted) {
        accepted.items.append(item)

        let progress = item.progress.publisher(for: \.fractionCompleted).sink { [weak self] _ in
            Task {
                await self?.handleProgressUpdates()
            }
        }
        accepted.observers.append(progress)

        Task { @MainActor in
            guard let media = try? ContextManager.shared.mainContext.existingObject(with: item.media) else { return }

            let completion = media.publisher(for: \.remoteStatusNumber).sink { [weak self] _ in
                Task {
                    await self?.handleStatusUpdates()
                }
            }
            await self.addObserver(completion)
        }
    }

    private func addObserver(_ cancellable: AnyCancellable) {
        guard case var .accepted(accepted) = state else { return }
        accepted.observers.append(cancellable)
        self.state = .accepted(accepted)
    }

    private func handleExpiration() {
        if case let .accepted(accepted) = state {
            Task { @MainActor in
                let context = ContextManager.shared.mainContext
                for item in accepted.items {
                    guard let media = try? context.existingObject(with: item.media) else { continue }
                    MediaCoordinator.shared.cancelUpload(of: media)
                }
            }
        }

        setTaskCompleted(success: false)
    }

    private func handleProgressUpdates() async {
        guard case let .accepted(accepted) = state else { return }

        let progresses = await MainActor.run {
            let context = ContextManager.shared.mainContext
            return accepted.items
                .filter { item in
                    (try? context.existingObject(with: item.media)) != nil
                }
                .map(\.progress)
        }

        let fractionCompleted = progresses.map(\.fractionCompleted).reduce(0, +) / Double(progresses.count)
        accepted.task.progress.completedUnitCount = Int64(fractionCompleted * Double(accepted.task.progress.totalUnitCount))
    }

    private func handleMediaObjectsUpdates(updated: Set<TaggedManagedObjectID<Media>>) async {
        guard case let .accepted(accepted) = state else { return }

        let needsUpdate = accepted.items.contains(where: { updated.contains($0.media) })
        if needsUpdate {
            await handleStatusUpdates()
        }
    }

    private func handleStatusUpdates() async {
        await updateMessaging()
        await updateResult()
    }

    private func updateMessaging() async {
        guard case let .accepted(accepted) = self.state else { return }

        let statuses = await MainActor.run {
            let context = ContextManager.shared.mainContext
            return accepted.items.compactMap { try? context.existingObject(with: $0.media).uploadStatus }
        }

        let failed = statuses.count { $0 == .failure }
        let success = statuses.count { $0 == .success}
        let uploading = statuses.count { $0 == .uploading }

        var subtitle = [String]()
        if uploading > 0 {
            subtitle.append(String.localizedStringWithFormat(Strings.uploadingStatus, uploading))
        }
        if success > 0 {
            subtitle.append(String.localizedStringWithFormat(Strings.successStatus, success))
        }
        if failed > 0 {
            subtitle.append(String.localizedStringWithFormat(Strings.failedStatus, failed))
        }

        accepted.task.updateTitle(Strings.uploadingMediaTitle, subtitle: ListFormatter.localizedString(byJoining: subtitle))
    }

    private func updateResult() async {
        guard case let .accepted(accepted) = self.state else { return }

        let mediaStatuses = await MainActor.run {
            let context = ContextManager.shared.mainContext
            return accepted.items.compactMap { try? context.existingObject(with: $0.media).uploadStatus }
        }

        let completed = mediaStatuses.allSatisfy { $0 == .success || $0 == .failure }
        guard completed else {
            return
        }

        let success = mediaStatuses.allSatisfy { $0 == .success }
        setTaskCompleted(success: success)
    }

    private func setTaskCompleted(success: Bool) {
        guard case let .accepted(accepted) = self.state else { return }
        DDLogInfo("BGTask completed with success? \(success)")

        accepted.task.setTaskCompleted(success: success)
        self.state = .idle
    }
}

private enum MediaUploadStatus: Hashable {
    case success
    case failure
    case uploading
    case unknown
}

private extension Media {
    var uploadStatus: MediaUploadStatus {
        if let number = remoteStatusNumber, let status = MediaRemoteStatus(rawValue: number.uintValue) {
            switch status {
            case .sync:
                return .success
            case .failed:
                return .failure
            case .pushing, .processing:
                return .uploading
            default:
                return .unknown
            }
        } else {
            return .unknown
        }
    }
}

private enum Strings {
    static let uploadingMediaTitle = NSLocalizedString(
        "BGTask.mediaUpload.title",
        value: "Uploading media",
        comment: "Title shown in background task when uploading media files"
    )

    static let uploadingStatus = NSLocalizedString(
        "BGTask.mediaUpload.uploading",
        value: "%1$d uploading",
        comment: "Status message showing number of files currently uploading. %1$d is the count of uploading files."
    )

    static let successStatus = NSLocalizedString(
        "BGTask.mediaUpload.successful",
        value: "%1$d successful",
        comment: "Status message showing number of files uploaded successfully. %1$d is the count of successful uploads."
    )

    static let failedStatus = NSLocalizedString(
        "BGTask.mediaUpload.failed",
        value: "%1$d failed",
        comment: "Status message showing number of files that failed to upload. %1$d is the count of failed uploads."
    )
}

import Foundation
import WordPressKit
import WordPressShared

/// Tracks backup download status for a WordPress site.
/// Automatically polls for updates while a backup is in progress or until a download becomes available.
@MainActor
final class DownloadableBackupTracker: ObservableObject {
    @Published var backupStatus: JetpackBackup?

    private let blog: Blog
    private var refreshTask: Task<Void, Never>?

    /// Returns the download URL if a valid backup is available.
    var downloadURL: URL? {
        guard let backupStatus,
              let validUntil = backupStatus.validUntil,
              Date() < validUntil,
              let url = backupStatus.url.flatMap(URL.init) else {
            return nil
        }
        return url
    }

    /// Indicates whether a backup is currently being created.
    var isBackupInProgress: Bool {
        guard let backupStatus,
              let progress = backupStatus.progress,
              progress > 0 && progress < 100 else {
            return false
        }
        return true
    }

    /// Convenience property to check if a download is available.
    var isDownloadAvailable: Bool {
        downloadURL != nil
    }

    init(blog: Blog) {
        self.blog = blog
    }

    /// Starts tracking backup status. Refreshes immediately and polls as needed.
    func startTracking() {
        refreshBackupStatus()
    }

    /// Stops tracking and cancels any pending refresh operations.
    func stopTracking() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Refreshes backup status and starts continuous polling with adaptive delays.
    func refreshBackupStatus() {
        guard let siteRef = JetpackSiteRef(blog: blog), siteRef.isBackupFeatureAvailable else {
            return
        }

        refreshTask?.cancel()
        refreshTask = Task {
            var pollCount = 0

            // Fetch status immediately
            await fetchBackupStatus(siteRef: siteRef)

            // Continue polling while on the screen
            while !Task.isCancelled {
                let delay: UInt64

                if isBackupInProgress {
                    // Poll frequently (every 5 seconds) when backup is in progress
                    delay = 5_000_000_000
                } else {
                    // Progressive delay: 10s * (attemptCount + 1), max 60s
                    let seconds = min(10 * (pollCount + 1), 60)
                    delay = UInt64(seconds) * 1_000_000_000
                    pollCount += 1
                }

                try? await Task.sleep(nanoseconds: delay)

                guard !Task.isCancelled else { break }

                await fetchBackupStatus(siteRef: siteRef)

                // Reset poll count if backup starts
                if isBackupInProgress {
                    pollCount = 0
                }
            }
        }
    }

    private func fetchBackupStatus(siteRef: JetpackSiteRef) async {
        do {
            let backupService = JetpackBackupService(coreDataStack: ContextManager.shared)
            let statuses = try await backupService.getAllBackupStatus(for: siteRef)

            guard !Task.isCancelled else { return }

            // Get the most recently started backup
            self.backupStatus = statuses.max { lhs, rhs in
                (lhs.startedAt ?? .distantPast) < (rhs.startedAt ?? .distantPast)
            }
        } catch {
            guard !Task.isCancelled else { return }
            // Silently fail - backup status remains unchanged
        }
    }

    /// Dismisses the current backup notice, clearing it from the UI and notifying the server.
    func dismissBackupNotice() {
        guard let siteRef = JetpackSiteRef(blog: blog),
              let downloadID = backupStatus?.downloadID else {
            return
        }

        // Clear local state immediately for better UX
        backupStatus = nil

        // Dismiss on the server (fire and forget)
        Task {
            let backupService = JetpackBackupService(coreDataStack: ContextManager.shared)
            await backupService.dismissBackupNotice(site: siteRef, downloadID: downloadID)
        }
    }
}

// MARK: - JetpackBackupService Async Extensions

private extension JetpackBackupService {
    func getAllBackupStatus(for siteRef: JetpackSiteRef) async throws -> [JetpackBackup] {
        try await withCheckedThrowingContinuation { continuation in
            getAllBackupStatus(for: siteRef) { statuses in
                continuation.resume(returning: statuses)
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }

    func dismissBackupNotice(site: JetpackSiteRef, downloadID: Int) async {
        await withCheckedContinuation { continuation in
            dismissBackupNotice(site: site, downloadID: downloadID)
            continuation.resume()
        }
    }
}

import Foundation
import WordPressKit
import WordPressShared
import CocoaLumberjack

/// Tracks backup download status for a WordPress site.
/// Automatically polls for updates while a backup is in progress or until a download becomes available.
@MainActor
final class DownloadableBackupTracker: ObservableObject {
    @Published var backup: JetpackBackup?

    private let blog: Blog
    private var refreshTask: Task<Void, Never>?

    init(blog: Blog) {
        self.blog = blog
    }

    /// Starts tracking backup status. Refreshes immediately and polls as needed.
    func startTracking() {
        DDLogInfo("[DownloadableBackup] Starting backup tracking for site")
        refreshBackupStatus()
    }

    /// Stops tracking and cancels any pending refresh operations.
    func stopTracking() {
        DDLogInfo("[DownloadableBackup] Stopping backup tracking")
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Refreshes backup status and starts continuous polling with adaptive delays.
    func refreshBackupStatus() {
        guard let siteRef = JetpackSiteRef(blog: blog), siteRef.hasBackup else {
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

                // Check if backup is in progress or processing
                let isActive = backup?.progress.map { $0 > 0 && $0 < 100 } ?? false ||
                              (backup?.progress == 100 && backup?.url == nil)

                if isActive {
                    // Poll frequently (every 5 seconds) when backup is active
                    delay = 2_000_000_000
                    pollCount = 0
                } else {
                    // Progressive delay: 10s * (attemptCount + 1), max 60s
                    let seconds = min(10 * (pollCount + 1), 60)
                    delay = UInt64(seconds) * 1_000_000_000
                    pollCount += 1
                }

                try? await Task.sleep(nanoseconds: delay)

                guard !Task.isCancelled else { break }

                await fetchBackupStatus(siteRef: siteRef)
            }
        }
    }

    private func fetchBackupStatus(siteRef: JetpackSiteRef) async {
        do {
            let backupService = JetpackBackupService(coreDataStack: ContextManager.shared)
            let statuses = try await backupService.getAllBackupStatus(for: siteRef)

            guard !Task.isCancelled else { return }

            // Get the most recently started backup
            self.backup = statuses.max { lhs, rhs in
                lhs.startedAt < rhs.startedAt
            }

            if let backup {
                let statusInfo = "progress: \(backup.progress ?? 0)%, downloadID: \(backup.downloadID), url: \(String(describing: backup.url))"
                DDLogInfo("[DownloadableBackup] Status updated: \(statusInfo)")
            } else {
                DDLogInfo("[DownloadableBackup] No active downloadable backups found")
            }
        } catch {
            guard !Task.isCancelled else { return }
            DDLogError("[DownloadableBackup] Failed to fetch backup status: \(error)")
        }
    }

    /// Dismisses the current backup notice, clearing it from the UI and notifying the server.
    func dismissBackupNotice() {
        guard let siteRef = JetpackSiteRef(blog: blog), let backup else {
            return
        }

        let downloadID = backup.downloadID

        // Clear local state immediately for better UX
        self.backup = nil
        DDLogInfo("[DownloadableBackup] Dismissing backup notice for download ID: \(downloadID)")

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

import Foundation
import WordPressKit
import WordPressShared

/// Tracks backup download status for a WordPress site.
/// Automatically polls for updates while a backup is in progress or until a download becomes available.
@MainActor
final class BackupDownloadTracker: ObservableObject {
    @Published var backupStatus: JetpackBackup?
    @Published var isLoading = false
    @Published var error: Error?

    private let blog: Blog
    private var refreshTask: Task<Void, Never>?

    /// Returns the download URL if a valid backup is available.
    /// - Returns: URL for downloading the backup, or nil if unavailable.
    func downloadURL() -> URL? {
        guard let backupStatus,
              let validUntil = backupStatus.validUntil,
              Date() < validUntil,
              backupStatus.backupPoint != nil,
              let urlString = backupStatus.url,
              backupStatus.downloadID != nil else {
            return nil
        }
        return URL(string: urlString)
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

    /// Refreshes backup status and starts polling if a backup is in progress or no download is available.
    func refreshBackupStatus() {
        guard let siteRef = JetpackSiteRef(blog: blog),
              siteRef.hasBackup else {
            return
        }

        refreshTask?.cancel()
        refreshTask = Task {
            // Fetch status immediately
            await fetchBackupStatus(siteRef: siteRef)
            
            // Continue polling if needed (backup in progress or no download available)
            while !Task.isCancelled && (isBackupInProgress || downloadURL() == nil) {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                guard !Task.isCancelled else { break }
                
                await fetchBackupStatus(siteRef: siteRef)
                
                // Stop polling if download is now available and no backup in progress
                if downloadURL() != nil && !isBackupInProgress {
                    break
                }
            }
        }
    }

    private func fetchBackupStatus(siteRef: JetpackSiteRef) async {
        isLoading = true
        error = nil

        do {
            let backupService = JetpackBackupService(coreDataStack: ContextManager.shared)
            let statuses = try await backupService.getAllBackupStatus(for: siteRef)
            
            guard !Task.isCancelled else { return }

            // Get the first valid backup status
            self.backupStatus = statuses.first { status in
                if let validUntil = status.validUntil {
                    return Date() < validUntil
                }
                return false
            }
            self.isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            self.isLoading = false
            self.error = error
        }
    }

    /// Dismisses the current backup notice, clearing it from the UI and notifying the server.
    func dismissBackupNotice() async {
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

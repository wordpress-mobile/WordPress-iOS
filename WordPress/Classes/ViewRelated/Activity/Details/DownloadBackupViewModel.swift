import Foundation
import WordPressKit
import WordPressShared

@MainActor
final class DownloadBackupViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case success
        case failure
    }
    
    @Published var state: State = .idle
    @Published var errorMessage: String?
    @Published var downloadURL: String?
    
    // Download options
    @Published var includeThemes = true
    @Published var includePlugins = true
    @Published var includeUploads = true
    @Published var includeContent = true
    
    var hasSelection: Bool {
        includeThemes || includePlugins || includeUploads || includeContent
    }
    
    private let activity: Activity
    private let site: JetpackSiteRef
    private let backupService: JetpackBackupService
    private var downloadID: Int?
    
    init(activity: Activity, site: JetpackSiteRef) {
        self.activity = activity
        self.site = site
        self.backupService = JetpackBackupService(coreDataStack: ContextManager.shared.contextManager.mainContext)
    }
    
    func downloadBackup() {
        guard state == .idle, hasSelection else { return }
        
        state = .loading
        errorMessage = nil
        downloadURL = nil
        
        let restoreTypes = buildRestoreTypes()
        
        backupService.prepareBackup(
            for: site,
            rewindID: activity.rewindID,
            restoreTypes: restoreTypes,
            success: { [weak self] backup in
                self?.handleBackupPrepared(backup)
            },
            failure: { [weak self] error in
                self?.handleBackupFailure(error)
            }
        )
    }
    
    private func buildRestoreTypes() -> JetpackRestoreTypes {
        var types = JetpackRestoreTypes()
        types.themes = includeThemes
        types.plugins = includePlugins
        types.uploads = includeUploads
        types.sqls = includeContent
        types.roots = includeContent
        types.contents = includeContent
        return types
    }
    
    private func handleBackupPrepared(_ backup: JetpackBackup) {
        downloadID = backup.downloadID
        
        // Check if backup is already ready
        if let url = backup.url, !url.isEmpty {
            downloadURL = url
            state = .success
            WPAnalytics.track(.backupDownloadSucceeded, properties: ["source": "activity_detail"])
        } else {
            // Start polling for backup status
            pollBackupStatus()
        }
    }
    
    private func pollBackupStatus() {
        guard let downloadID = downloadID else {
            handleBackupFailure(BackupError.missingDownloadID)
            return
        }
        
        backupService.getBackupStatus(
            for: site,
            downloadID: downloadID,
            success: { [weak self] backup in
                self?.handleBackupStatus(backup)
            },
            failure: { [weak self] error in
                self?.handleBackupFailure(error)
            }
        )
    }
    
    private func handleBackupStatus(_ backup: JetpackBackup) {
        if let url = backup.url, !url.isEmpty {
            // Backup is ready
            downloadURL = url
            state = .success
            WPAnalytics.track(.backupDownloadSucceeded, properties: ["source": "activity_detail"])
        } else if backup.progress == nil {
            // Backup failed
            state = .failure
            errorMessage = Strings.defaultErrorMessage
            WPAnalytics.track(.backupDownloadFailed, properties: ["source": "activity_detail", "error": "no_progress"])
        } else {
            // Still in progress, continue polling
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard self?.state == .loading else { return }
                self?.pollBackupStatus()
            }
        }
    }
    
    private func handleBackupFailure(_ error: Error) {
        state = .failure
        
        if let networkError = error as? NSError {
            errorMessage = networkError.localizedDescription
        } else {
            errorMessage = Strings.defaultErrorMessage
        }
        
        WPAnalytics.track(.backupDownloadFailed, properties: [
            "source": "activity_detail",
            "error": error.localizedDescription
        ])
    }
}

// MARK: - Errors

private enum BackupError: LocalizedError {
    case missingDownloadID
    
    var errorDescription: String? {
        switch self {
        case .missingDownloadID:
            return Strings.missingDownloadIDError
        }
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let defaultErrorMessage = NSLocalizedString(
        "download.viewModel.error.default",
        value: "An error occurred while preparing your backup. Please try again.",
        comment: "Default error message for backup download failures"
    )
    
    static let missingDownloadIDError = NSLocalizedString(
        "download.viewModel.error.missingID",
        value: "Unable to track backup progress. Please try again.",
        comment: "Error when download ID is missing"
    )
}
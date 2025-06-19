import Foundation
import WordPressKit
import WordPressShared

@MainActor
final class RestoreBackupViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case success
        case failure
    }
    
    @Published var state: State = .idle
    @Published var errorMessage: String?
    
    private let activity: Activity
    private let blog: Blog
    private let site: JetpackSiteRef
    private let restoreService: JetpackRestoreService
    private let activityStore: ActivityStore
    
    init(activity: Activity, blog: Blog) {
        self.activity = activity
        self.blog = blog
        guard let siteRef = JetpackSiteRef(blog: blog) else {
            fatalError("Invalid blog for restore")
        }
        self.site = siteRef
        self.restoreService = JetpackRestoreService(coreDataStack: ContextManager.shared.contextManager)
        self.activityStore = StoreContainer.shared.activity
    }
    
    func restore() {
        guard state == .idle else { return }
        
        state = .loading
        errorMessage = nil
        
        restoreService.restoreSite(
            site,
            rewindID: activity.rewindID,
            restoreTypes: nil, // nil means restore everything
            success: { [weak self] restoreID, jobID in
                self?.handleRestoreStarted(restoreID: restoreID, jobID: jobID)
            },
            failure: { [weak self] error in
                self?.handleRestoreFailure(error)
            }
        )
    }
    
    private func handleRestoreStarted(restoreID: String, jobID: Int) {
        // Start monitoring the restore status
        pollRestoreStatus()
    }
    
    private func pollRestoreStatus() {
        restoreService.getRewindStatus(
            for: site,
            success: { [weak self] rewindStatus in
                self?.handleRewindStatus(rewindStatus)
            },
            failure: { [weak self] error in
                self?.handleRestoreFailure(error)
            }
        )
    }
    
    private func handleRewindStatus(_ rewindStatus: RewindStatus) {
        guard let restoreStatus = rewindStatus.restore else {
            // No active restore, check if we need to keep polling
            if state == .loading {
                // Continue polling after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard self?.state == .loading else { return }
                    self?.pollRestoreStatus()
                }
            }
            return
        }
        
        switch restoreStatus.status {
        case .finished:
            state = .success
            WPAnalytics.track(.restoreSucceeded, properties: ["source": "activity_detail"])
            
        case .fail:
            state = .failure
            errorMessage = restoreStatus.message ?? Strings.defaultErrorMessage
            WPAnalytics.track(.restoreFailed, properties: ["source": "activity_detail", "error": errorMessage ?? "unknown"])
            
        case .running, .queued:
            // Continue polling
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard self?.state == .loading else { return }
                self?.pollRestoreStatus()
            }
            
        default:
            break
        }
    }
    
    private func handleRestoreFailure(_ error: Error) {
        state = .failure
        
        if let networkError = error as? NSError {
            errorMessage = networkError.localizedDescription
        } else {
            errorMessage = Strings.defaultErrorMessage
        }
        
        WPAnalytics.track(.restoreFailed, properties: [
            "source": "activity_detail",
            "error": error.localizedDescription
        ])
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let defaultErrorMessage = NSLocalizedString(
        "restore.viewModel.error.default",
        value: "An error occurred while restoring your site. Please try again.",
        comment: "Default error message for restore failures"
    )
}
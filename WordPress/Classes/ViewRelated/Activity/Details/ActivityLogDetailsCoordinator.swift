import UIKit
import SwiftUI
import WordPressKit

/// Coordinator to handle navigation from SwiftUI ActivityLogDetailsView to UIKit view controllers
class ActivityLogDetailsCoordinator: UIViewRepresentable {
    static weak var shared: ActivityLogDetailsCoordinator?
    
    let activity: Activity
    let blog: Blog
    
    init(activity: Activity, blog: Blog) {
        self.activity = activity
        self.blog = blog
        ActivityLogDetailsCoordinator.shared = self
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func presentRestore() {
        guard let viewController = topViewController(),
              let siteRef = JetpackSiteRef(blog: blog),
              activity.isRewindable,
              activity.rewindID != nil else {
            return
        }
        
        // Check if the store has the credentials status cached
        let store = StoreContainer.shared.activity
        let isAwaitingCredentials = store.isAwaitingCredentials(site: siteRef)
        
        let restoreViewController = JetpackRestoreOptionsViewController(
            site: siteRef,
            activity: activity,
            isAwaitingCredentials: isAwaitingCredentials
        )
        
        restoreViewController.presentedFrom = "activity_detail"
        
        let navigationController = UINavigationController(rootViewController: restoreViewController)
        navigationController.modalPresentationStyle = .formSheet
        
        viewController.present(navigationController, animated: true)
    }
    
    func presentBackup() {
        guard let viewController = topViewController(),
              let siteRef = JetpackSiteRef(blog: blog) else {
            return
        }
        
        let backupViewController = JetpackBackupOptionsViewController(
            site: siteRef,
            activity: activity
        )
        
        backupViewController.presentedFrom = "activity_detail"
        
        let navigationController = UINavigationController(rootViewController: backupViewController)
        navigationController.modalPresentationStyle = .formSheet
        
        viewController.present(navigationController, animated: true)
    }
    
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}
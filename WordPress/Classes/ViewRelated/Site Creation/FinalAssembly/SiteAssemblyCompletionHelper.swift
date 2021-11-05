typealias HomepageEditorCompletion = () -> Void

class SiteAssemblyCompletionHelper {
    static func completeSiteCreation(for blog: Blog) {
        // branch here for explat variation
        if ABTest.landInTheEditorPhase1.variation == .control {
            showMySitesScreen(for: blog)
        } else {
            landInTheEditor(for: blog)
        }
    }

    private static func landInTheEditor(for blog: Blog) {
        fetchAllPages(for: blog, success: { _ in
            DispatchQueue.main.async {
                WPTabBarController.sharedInstance()?.showHomePageEditor(forBlog: blog) {
                    showMySitesScreen(for: blog)
                }
            }
        }, failure: { _ in
            NSLog("Fetching all pages failed after site creation!")
        })
    }

    private static func showMySitesScreen(for blog: Blog) {
        WPTabBarController.sharedInstance()?.mySitesCoordinator.showBlogDetails(for: blog)
        showQuickStartAlert(for: blog)
    }

    // This seems to be necessary before casting `AbstractPost` to `Page`.
    private static func fetchAllPages(for blog: Blog, success: @escaping PostServiceSyncSuccess, failure: @escaping PostServiceSyncFailure) {
        let options = PostServiceSyncOptions()
        options.number = 20
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        postService.syncPosts(ofType: .page, with: options, for: blog, success: success, failure: failure)
    }

    private static func showQuickStartAlert(for blog: Blog) {
        guard !UserDefaults.standard.quickStartWasDismissedPermanently else {
            return
        }

        guard let tabBar = WPTabBarController.sharedInstance() else {
            return
        }

        let fancyAlert = FancyAlertViewController.makeQuickStartAlertController(blog: blog)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = tabBar
        tabBar.present(fancyAlert, animated: true)
    }
}

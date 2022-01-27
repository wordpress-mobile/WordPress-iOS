typealias HomepageEditorCompletion = () -> Void

class SiteAssemblyCompletionHelper {
    static func completeSiteCreation(for blog: Blog, quickStartSettings: QuickStartSettings) {
        // branch here for explat variation
        if ABTest.landInTheEditorPhase1.variation == .control {
            showMySitesScreen(for: blog, quickStartSettings: quickStartSettings)
        } else {
            landInTheEditor(for: blog, quickStartSettings: quickStartSettings)
        }
    }

    static func completeSiteCreationFromAuthenticationScreen(for blog: Blog, quickStartSettings: QuickStartSettings, navigationController: UINavigationController, completion: @escaping HomepageEditorCompletion) {
        // branch here for explat variation
        if ABTest.landInTheEditorPhase1.variation == .control {
            completion()
        } else {
            landInTheEditor(for: blog, quickStartSettings: quickStartSettings, navigationController: navigationController, completion: completion)
        }

    }

    private static func landInTheEditor(for blog: Blog, quickStartSettings: QuickStartSettings) {
        fetchAllPages(for: blog, success: { _ in
            DispatchQueue.main.async {
                WPTabBarController.sharedInstance()?.showHomePageEditor(forBlog: blog) {
                    showMySitesScreen(for: blog, quickStartSettings: quickStartSettings)
                }
            }
            WPAnalytics.track(.landingEditorShown)
        }, failure: { _ in
            NSLog("Fetching all pages failed after site creation!")
        })
    }

    private static func landInTheEditor(for blog: Blog, quickStartSettings: QuickStartSettings, navigationController: UINavigationController, completion: @escaping HomepageEditorCompletion) {
        fetchAllPages(for: blog, success: { _ in
            DispatchQueue.main.async {
                if let homepage = blog.homepage {
                    let editorViewController = EditPageViewController(homepage: homepage, completion: completion)
                    navigationController.present(editorViewController, animated: false)
                }
                WPAnalytics.track(.landingEditorShown)
            }
        }, failure: { _ in
            NSLog("Fetching all pages failed after site creation!")
        })
    }

    private static func showMySitesScreen(for blog: Blog, quickStartSettings: QuickStartSettings) {
        WPTabBarController.sharedInstance()?.mySitesCoordinator.showBlogDetails(for: blog)
        showQuickStartPrompt(for: blog, quickStartSettings: quickStartSettings)
    }

    // This seems to be necessary before casting `AbstractPost` to `Page`.
    private static func fetchAllPages(for blog: Blog, success: @escaping PostServiceSyncSuccess, failure: @escaping PostServiceSyncFailure) {
        let options = PostServiceSyncOptions()
        options.number = 20
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        postService.syncPosts(ofType: .page, with: options, for: blog, success: success, failure: failure)
    }

    private static func showQuickStartPrompt(for blog: Blog, quickStartSettings: QuickStartSettings) {
        guard !quickStartSettings.promptWasDismissed(for: blog) else {
            return
        }

        guard let tabBar = WPTabBarController.sharedInstance() else {
            return
        }

        let quickstartPrompt = QuickStartPromptViewController(blog: blog)
        quickstartPrompt.onDismiss = { blog, showQuickStart in
            if showQuickStart {
                QuickStartTourGuide.shared.setupWithDelay(for: blog)
            }
        }
        tabBar.present(quickstartPrompt, animated: true)
    }
}

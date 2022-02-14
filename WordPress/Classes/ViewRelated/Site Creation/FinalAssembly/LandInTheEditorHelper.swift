typealias HomepageEditorCompletion = () -> Void

class LandInTheEditorHelper {
    /// Land in the editor, or continue as usual for the control group -  Used to branch on the ExPlat experiment for landing in the editor from the site creation flow
    /// - Parameter blog: Blog (which was just created) for which to show the home page editor
    /// - Parameter navigationController: UINavigationController used to present the home page editor
    /// - Parameter completion: HomepageEditorCompletion callback to be invoked after the user finishes editing the home page, or immediately in the control group case
    static func landInTheEditorOrContinue(for blog: Blog, navigationController: UINavigationController, completion: @escaping HomepageEditorCompletion) {
        // branch here for explat variation
        if ABTest.landInTheEditorPhase1.variation == .control {
            completion()
        } else {
            landInTheEditor(for: blog, navigationController: navigationController, completion: completion)
        }
    }

    private static func landInTheEditor(for blog: Blog, navigationController: UINavigationController, completion: @escaping HomepageEditorCompletion) {
        fetchAllPages(for: blog, success: { _ in
            DispatchQueue.main.async {
                if let homepage = blog.homepage {
                    let editorViewController = EditPageViewController(homepage: homepage, completion: completion)
                    navigationController.present(editorViewController, animated: false)
                    WPAnalytics.track(.landingEditorShown)
                }
            }
        }, failure: { _ in
            NSLog("Fetching all pages failed after site creation!")
        })
    }

    // This seems to be necessary before casting `AbstractPost` to `Page`.
    private static func fetchAllPages(for blog: Blog, success: @escaping PostServiceSyncSuccess, failure: @escaping PostServiceSyncFailure) {
        let options = PostServiceSyncOptions()
        options.number = 20
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        postService.syncPosts(ofType: .page, with: options, for: blog, success: success, failure: failure)
    }
}

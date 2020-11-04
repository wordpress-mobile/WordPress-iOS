import CoreData
import Foundation

extension UIViewController {
    func addMeButtonToNavigationBar(for blog: Blog) {
        navigationItem.rightBarButtonItem = UIBarButtonItem.makeMeButtonItem(email: blog.account?.email,
                                                                             target: self,
                                                                             action: #selector(presentMeScene))
    }

    @objc
    private func presentMeScene() {
        MeScenePresenter().present(on: self, animated: true, completion: nil)
    }
}

class MySiteViewController: UIViewController, NoResultsViewHost {

    // MARK: - Blog

    /// Convenience setter and getter for the blog.  This calculated property takes care of showing the appropriate VC, depending
    /// on whether there's a blog to show or not.
    ///
    var blog: Blog? {
        set {
            guard let newBlog = newValue else {
                showBlogDetailsForMainBlogOrNoSites()
                return
            }

            showBlogDetails(for: newBlog)
        }

        get {
            guard let blogDetailsViewController = blogDetailsViewController else {
                return nil
            }

            return blogDetailsViewController.blog
        }
    }

    /// The VC for the blog details.  This class is written in a way that this VC will only exist if it's being shown on screen.
    /// Please keep this in mind when making modifications.
    ///
    private var blogDetailsViewController: BlogDetailsViewController? = nil

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        setupNavigationItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if blog == nil {
            showBlogDetailsForMainBlogOrNoSites()
        }
    }

    // MARK: - Navigation Item

    private func setupNavigationItem() {
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = NSLocalizedString("My Site", comment: "Title of My Site tab")
    }

    // MARK: - Main Blog

    /// Convenience method to retrieve the main blog for an account when none is selected.
    ///
    /// - Returns:the main blog for an account (last selected, or first blog in list).
    ///
    private func mainBlog() -> Blog? {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
        return blogService.lastUsedOrFirstBlog()
    }

    /// This VC is prepared to either show the details for a blog, or show a no-results VC configured to let the user know they have no blogs.
    /// There's no scenario where this is shown empty, for an account that HAS blogs.
    ///
    /// In order to adhere to this logic, if this VC is shown without a blog being set, we will try to load the "main" blog (ie in order: the last used blog,
    /// the account's primary blog, or the first blog we find for the account).
    ///
    private func showBlogDetailsForMainBlogOrNoSites() {
        guard let mainBlog = mainBlog() else {
            showNoSites()
            return
        }

        showBlogDetails(for: mainBlog)
    }

    // MARK: - No Sites UI logic

    private func hideNoSites() {
        hideNoResults()
    }

    private func showNoSites() {
        hideBlogDetails()

        configureAndDisplayNoResults(
            on: view,
            title: NSLocalizedString(
                "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.",
                comment: "Text shown when the account has no sites."),
            buttonTitle: NSLocalizedString(
                "Add new site",
                comment: "Title of button to add a new site."),
            image: "mysites-nosites")
    }

    // MARK: - Blog Details UI Logic

    private func hideBlogDetails() {
        guard let blogDetailsViewController = blogDetailsViewController else {
            return
        }

        remove(blogDetailsViewController)
        self.blogDetailsViewController = nil
    }

    /// Shows a `BlogDetailsViewController` for the specified `Blog`.  If the VC doesn't exist, this method also takes care
    /// of creating it.
    ///
    /// - Parameters:
    ///         - blog: The blog to show the details of.
    ///
    private func showBlogDetails(for blog: Blog) {
        let blogDetailsViewController = self.blogDetailsViewController(for: blog)

        add(blogDetailsViewController)

        blogDetailsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(blogDetailsViewController.view)
    }

    private func blogDetailsViewController(for blog: Blog) -> BlogDetailsViewController {
        guard let blogDetailsViewController = blogDetailsViewController else {
            let blogDetailsViewController = makeBlogDetailsViewController(for: blog)
            self.blogDetailsViewController = blogDetailsViewController
            return blogDetailsViewController
        }

        blogDetailsViewController.blog = blog
        return blogDetailsViewController
    }

    private func makeBlogDetailsViewController(for blog: Blog) -> BlogDetailsViewController {
        let blogDetailsViewController = BlogDetailsViewController(meScenePresenter: MeScenePresenter())
        blogDetailsViewController.blog = blog

        return blogDetailsViewController
    }

    // MARK: - Model Changes

    private func subscribeToModelChanges() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDataModelChange(notification:)),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: ContextManager.shared.mainContext)
    }

    @objc
    private func handleDataModelChange(notification: NSNotification) {
        if let blog = blog {
            handlePossibleDeletion(of: blog, notification: notification)
        } else {
            handlePossiblePrimaryBlogCreation()
        }
    }

    // MARK: - Model Changes: Blog Deletion

    /// This method takes care of figuring out if the selected blog was deleted, and to address any side effect
    /// of the selected blog being deleted.
    ///
    private func handlePossibleDeletion(of selectedBlog: Blog, notification: NSNotification) {
        guard let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>,
           deletedObjects.contains(selectedBlog) else {
            return
        }

        self.blog = nil
    }

    // MARK: - Model Changes: Blog Creation

    /// This method takes care of figuring out if a primary blog was created, in order to show the details for such
    /// blog.
    ///
    private func handlePossiblePrimaryBlogCreation() {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)

        guard let blog = blogService.primaryBlog() else {
            return
        }

        self.blog = blog
    }
}

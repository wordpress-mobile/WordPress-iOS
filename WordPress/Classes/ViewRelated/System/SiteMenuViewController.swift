import UIKit

protocol SiteMenuViewControllerDelegate: AnyObject {
    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController)
}

/// The site menu for the split view navigation.
final class SiteMenuViewController: UIViewController {
    private let blog: Blog
    private let blogDetailsVC = BlogDetailsViewController()

    weak var delegate: SiteMenuViewControllerDelegate?

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        blogDetailsVC.blog = blog
        blogDetailsVC.isSidebarModeEnabled = true
        blogDetailsVC.isScrollEnabled = true
        blogDetailsVC.presentationDelegate = self

        addChild(blogDetailsVC)
        view.addSubview(blogDetailsVC.view)
        blogDetailsVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(blogDetailsVC.view)

        blogDetailsVC.showInitialDetailsForBlog()

        navigationItem.title = blog.settings?.name ?? (blog.displayURL as String?) ?? ""
    }
}

extension SiteMenuViewController: BlogDetailsPresentationDelegate {
    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        delegate?.siteMenuViewController(self, showDetailsViewController: viewController)
    }
}

import UIKit
import WordPressData
import WordPressUI

protocol SiteMenuViewControllerDelegate: AnyObject {
    func siteMenuViewController(
        _ siteMenuViewController: SiteMenuViewController,
        showDetailsViewController viewController: UIViewController
    )
}

/// The site menu for the split view navigation.
final class SiteMenuViewController: UIViewController {
    let blog: Blog
    private let blogDetailsVC: BlogDetailsViewController

    weak var delegate: SiteMenuViewControllerDelegate?

    private var didAppear = false

    init(blog: Blog, usesAdaptiveNavigation: Bool = false) {
        self.blog = blog
        blogDetailsVC = BlogDetailsViewController(blog: blog)
        blogDetailsVC.usesAdaptiveNavigation = usesAdaptiveNavigation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        blogDetailsVC.blog = blog
        blogDetailsVC.isSidebarModeEnabled = true
        blogDetailsVC.presentationDelegate = self

        addChild(blogDetailsVC)
        view.addSubview(blogDetailsVC.view)
        blogDetailsVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(blogDetailsVC.view)
        blogDetailsVC.didMove(toParent: self)

        blogDetailsVC.showInitialDetailsForBlog()

        navigationItem.title = blog.settings?.name ?? (blog.displayURL) ?? ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        didAppear = true
    }

    func selectSubsection(_ subsection: BlogDetailsRowKind) {
        blogDetailsVC.tableViewModel?.restoreSelection(to: subsection)
    }

    func showSubsection(_ subsection: BlogDetailsRowKind, userInfo: [String: Any]) {
        blogDetailsVC.showDetailView(for: subsection, userInfo: userInfo)
    }
}

extension SiteMenuViewController: BlogDetailsPresentationDelegate {
    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        delegate?.siteMenuViewController(self, showDetailsViewController: viewController)

        // didAppear prevents it from being hidden on first show
        if didAppear, let splitVC = splitViewController, splitVC.splitBehavior == .overlay {
            DispatchQueue.main.async {
                splitVC.hide(splitVC.style == .doubleColumn ? .primary : .supplementary)
            }
        }
    }
}

import UIKit
import WordPressData
import WordPressUI

protocol SiteMenuViewControllerDelegate: AnyObject {
    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController)
}

/// The site menu for the split view navigation.
final class SiteMenuViewController: UIViewController {
    let blog: Blog
    private let blogDetailsVC: SiteMenuListViewController

    weak var delegate: SiteMenuViewControllerDelegate?

    private var tipObserver: TipObserver?
    private var didAppear = false
    private let tipAnchor = UIView()

    init(blog: Blog) {
        self.blog = blog
        blogDetailsVC = SiteMenuListViewController(blog: blog)
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

        navigationItem.title = blog.settings?.name ?? (blog.displayURL) ?? ""

    }

    private func getTipAnchor() -> UIView {
        if tipAnchor.superview != nil {
            return tipAnchor
        }
        guard let navigationBar = navigationController?.navigationBar else {
            return view // fallback
        }
        navigationBar.addSubview(tipAnchor)
        tipAnchor.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tipAnchor.widthAnchor.constraint(equalToConstant: 0),
            tipAnchor.heightAnchor.constraint(equalToConstant: 0),
            tipAnchor.leadingAnchor.constraint(equalTo: navigationBar.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            tipAnchor.topAnchor.constraint(equalTo: navigationBar.safeAreaLayoutGuide.topAnchor, constant: 40)
        ])
        return tipAnchor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if tipObserver == nil {
            tipObserver = registerTipPopover(AppTips.SidebarTip(), sourceItem: getTipAnchor(), arrowDirection: [.up])
        }

        didAppear = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        tipObserver = nil
    }

    func showSubsection(_ subsection: BlogDetailsRowKind, userInfo: [String: Any]) {
        blogDetailsVC.showDetailView(for: subsection, userInfo: userInfo)
    }
}

// Updates the `BlogDetailsViewController` style to match the native sidebar style.
private final class SiteMenuListViewController: BlogDetailsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewModel?.useSiteMenuStyle = true
    }
}

extension SiteMenuViewController: BlogDetailsPresentationDelegate {
    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        delegate?.siteMenuViewController(self, showDetailsViewController: viewController)

        // didAppear prevents it from being hidden on first show
        if didAppear, let splitVC = splitViewController, splitVC.splitBehavior == .overlay {
            DispatchQueue.main.async {
                splitVC.hide(.supplementary)
            }
        }
    }
}

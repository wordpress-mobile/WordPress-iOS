import UIKit

protocol SiteMenuViewControllerDelegate: AnyObject {
    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController)
}

/// The site menu for the split view navigation.
final class SiteMenuViewController: UIViewController {
    let blog: Blog
    private let blogDetailsVC = SiteMenuListViewController()

    weak var delegate: SiteMenuViewControllerDelegate?

    /// - warning: Temporary code. Avoid using it!
    var selectedSubsection: BlogDetailsSubsection? {
        let subsection = blogDetailsVC.selectedSubsection
        return subsection.rawValue == NSNotFound ? nil : subsection
    }

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

    func showSubsection(_ subsection: BlogDetailsSubsection, userInfo: [AnyHashable: Any]) {
        blogDetailsVC.showDetailView(for: subsection, userInfo: userInfo)
    }
}

// Updates the `BlogDetailsViewController` style to match the native sidebar style.
private final class SiteMenuListViewController: BlogDetailsViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = super.tableView(tableView, titleForHeaderInSection: section)
        return title == nil ? 0 : 48
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = super.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.text = title

        let headerView = UIView()
        headerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 20)
        ])
        return headerView
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = {
            let backgroundView = UIView()
            backgroundView.backgroundColor = .secondarySystemFill
            backgroundView.layer.cornerRadius = 10
            backgroundView.layer.cornerCurve = .continuous

            let container = UIView()
            container.addSubview(backgroundView)
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            container.pinSubviewToAllEdges(backgroundView, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            return container
        }()
        cell.focusStyle = .custom
        cell.focusEffect = nil

        return cell
    }
}

extension SiteMenuViewController: BlogDetailsPresentationDelegate {
    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        delegate?.siteMenuViewController(self, showDetailsViewController: viewController)

        if let splitVC = splitViewController, splitVC.splitBehavior == .overlay {
            DispatchQueue.main.async {
                splitVC.hide(.supplementary)
            }
        }
    }
}

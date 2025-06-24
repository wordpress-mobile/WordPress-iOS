import UIKit
import WordPressData
import WordPressUI

final class ReaderHomeViewController: ReaderStreamViewController {
    private let mainContext = ContextManager.shared.mainContext

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItems()
    }

    private func setupNavigationItems() {
        title = SharedStrings.Reader.home
        titleView.textLabel.text = SharedStrings.Reader.home
        navigationItem.titleView = titleView

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "wpl-add-card")?.resized(to: CGSize(width: 28, height: 28)), style: .plain, target: self, action: #selector(buttonCreatePostTapped))
    }

    override func headerForStream(_ topic: ReaderAbstractTopic?, container: UITableViewController) -> UIView? {
        let view = ReaderHeaderView()
        view.titleView.titleLabel.text = SharedStrings.Reader.home
        view.titleView.detailsTextView.text = Strings.homeDetails
        return view
    }

    @objc private func buttonCreatePostTapped() {
        if let blog = Blog.lastUsedOrFirst(in: mainContext) {
            showCreatePostScreen(blog: blog)
        } else {
            showCreateSiteFlow()
        }
    }

    private func showCreateSiteFlow() {
        let wizardLauncher = SiteCreationWizardLauncher()
        guard let wizard = wizardLauncher.ui else {
            return wpAssertionFailure("something went wrong")
        }
        present(wizard, animated: true)
        SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: "home")
    }

    private func showCreatePostScreen(blog: Blog) {
        let editorVC = EditPostViewController(blog: blog)
        editorVC.entryPoint = .dashboard
        present(editorVC, animated: true)
    }
}

private enum Strings {
    static let homeDetails = NSLocalizedString("reader.home.header.details", value: "Stay current with the blogs you've subscribed to.", comment: "Screen header details")
}

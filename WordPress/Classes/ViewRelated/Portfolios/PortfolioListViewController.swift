import UIKit
import WordPressKit

class PortfolioListViewController: UITableViewController {
    let siteID: Int
    fileprivate let noResultsView = WPNoResultsView()

    init(siteID: Int) {
        self.siteID = siteID
        super.init(style: .grouped)
        title = NSLocalizedString("Portfolios", comment: "Title for the Portfolios manager")
        noResultsView.delegate = self
    }

    convenience init?(blog: Blog) {
        guard let dotComID = blog.dotComID else {
            return nil
        }
        self.init(siteID: Int(dotComID))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - WPNoResultsViewDelegate

extension PortfolioListViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        let supportVC = SupportViewController()
        supportVC.showFromTabBar()
    }
}

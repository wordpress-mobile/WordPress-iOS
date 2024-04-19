import Foundation

final class SiteStatsSubscribersViewController: SiteStatsBaseTableViewController {
    private let viewModel: SiteStatsSubscribersViewModel

    init(viewModel: SiteStatsSubscribersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

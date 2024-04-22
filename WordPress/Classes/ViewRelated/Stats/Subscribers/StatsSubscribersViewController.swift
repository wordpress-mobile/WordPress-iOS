import Foundation

final class StatsSubscribersViewController: SiteStatsBaseTableViewController {
    private let viewModel: StatsSubscribersViewModel

    init(viewModel: StatsSubscribersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

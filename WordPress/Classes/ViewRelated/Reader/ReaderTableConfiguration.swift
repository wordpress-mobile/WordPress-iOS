struct ReaderTableConfiguration {
    private let footerViewNibName = "PostListFooterView"
    private let readerCardCellNibName = "ReaderPostCardCell"
    private let readerCardCellReuseIdentifier = "ReaderCardCellReuseIdentifier"
    private let readerBlockedCellNibName = "ReaderBlockedSiteCell"
    private let readerBlockedCellReuseIdentifier = "ReaderBlockedCellReuseIdentifier"
    private let readerGapMarkerCellNibName = "ReaderGapMarkerCell"
    private let readerGapMarkerCellReuseIdentifier = "ReaderGapMarkerCellReuseIdentifier"
    private let readerCrossPostCellNibName = "ReaderCrossPostCell"
    private let readerCrossPostCellReuseIdentifier = "ReaderCrossPostCellReuseIdentifier"

    func setup(_ tableView: UITableView) {
        setUpAccesibility(tableView)
        setUpSeparator(tableView)
        setUpCardCell(tableView)
        setUpBlockerCell(tableView)
        setUpGapMarkerCell(tableView)
        setUpCrossPostCell(tableView)
    }

    private func setUpAccesibility(_ tableView: UITableView) {
        tableView.accessibilityIdentifier = "Reader"
    }

    private func setUpSeparator(_ tableView: UITableView) {
        tableView.separatorStyle = .none
    }

    private func setUpCardCell(_ tableView: UITableView) {
        let nib = UINib(nibName: readerCardCellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: readerCardCellReuseIdentifier)
    }

    private func setUpBlockerCell(_ tableView: UITableView) {
        let nib = UINib(nibName: readerBlockedCellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: readerBlockedCellReuseIdentifier)
    }

    private func setUpGapMarkerCell(_ tableView: UITableView) {
        let nib = UINib(nibName: readerGapMarkerCellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: readerGapMarkerCellReuseIdentifier)
    }

    private func setUpCrossPostCell(_ tableView: UITableView) {
        let nib = UINib(nibName: readerCrossPostCellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: readerCrossPostCellReuseIdentifier)
    }
}

/// Registration and dequeuing of cells for table views in Reader
final class ReaderTableConfiguration {
    private let footerViewNibName = "PostListFooterView"
    private let readerCardCellNibName = "ReaderPostCardCell"
    private let readerCardCellReuseIdentifier = "ReaderCardCellReuseIdentifier"
    private let readerBlockedCellNibName = "ReaderBlockedSiteCell"
    private let readerBlockedCellReuseIdentifier = "ReaderBlockedCellReuseIdentifier"
    private let readerGapMarkerCellNibName = "ReaderGapMarkerCell"
    private let readerGapMarkerCellReuseIdentifier = "ReaderGapMarkerCellReuseIdentifier"
    private let readerCrossPostCellNibName = "ReaderCrossPostCell"
    private let readerCrossPostCellReuseIdentifier = "ReaderCrossPostCellReuseIdentifier"

    private let rowHeight = CGFloat(300.0)

    func setup(_ tableView: UITableView) {
        setupAccessibility(tableView)
        setUpSeparator(tableView)
        setUpCardCell(tableView)
        setUpBlockerCell(tableView)
        setUpGapMarkerCell(tableView)
        setUpCrossPostCell(tableView)
    }

    private func setupAccessibility(_ tableView: UITableView) {
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

    func footer() -> PostListFooterView {
        guard let footer = Bundle.main.loadNibNamed(footerViewNibName, owner: nil, options: nil)?.first as? PostListFooterView else {
            assertionFailure("Failed to load view from nib named \(footerViewNibName)")
            return PostListFooterView()
        }
        return footer
    }

    func estimatedRowHeight() -> CGFloat {
        return rowHeight
    }

    func crossPostCell(_ tableView: UITableView) -> ReaderCrossPostCell {
        return tableView.dequeueReusableCell(withIdentifier: readerCrossPostCellReuseIdentifier) as! ReaderCrossPostCell
    }

    func postCardCell(_ tableView: UITableView) -> ReaderPostCardCell {
        return tableView.dequeueReusableCell(withIdentifier: readerCardCellReuseIdentifier) as! ReaderPostCardCell
    }

    func gapMarkerCell(_ tableView: UITableView) -> ReaderGapMarkerCell {
        return tableView.dequeueReusableCell(withIdentifier: readerGapMarkerCellReuseIdentifier) as! ReaderGapMarkerCell
    }

    func blockedSiteCell(_ tableView: UITableView) -> ReaderBlockedSiteCell {
        return tableView.dequeueReusableCell(withIdentifier: readerBlockedCellReuseIdentifier) as! ReaderBlockedSiteCell
    }
}

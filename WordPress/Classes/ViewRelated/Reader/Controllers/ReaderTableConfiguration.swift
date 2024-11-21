import UIKit

/// Registration and dequeuing of cells for table views in Reader
final class ReaderTableConfiguration {
    private let postCellReuseIdentifier = "ReaderPostCellReuseIdentifier"
    private let crossPostCellReuseIdentifier = "ReaderCrossPostCellReuseIdentifier"
    private let blockedCellNibName = "ReaderBlockedSiteCell"
    private let blockedCellReuseIdentifier = "ReaderBlockedCellReuseIdentifier"
    private let gapMarkerCellNibName = "ReaderGapMarkerCell"
    private let gapMarkerCellReuseIdentifier = "ReaderGapMarkerCellReuseIdentifier"

    private let rowHeight = CGFloat(415.0)

    func setup(_ tableView: UITableView) {
        setupAccessibility(tableView)
        setUpBlockerCell(tableView)
        setUpGapMarkerCell(tableView)

        tableView.register(ReaderPostCell.self, forCellReuseIdentifier: postCellReuseIdentifier)
        tableView.register(ReaderCrossPostCell.self, forCellReuseIdentifier: crossPostCellReuseIdentifier)
    }

    private func setupAccessibility(_ tableView: UITableView) {
        tableView.accessibilityIdentifier = "reader_table_view"
    }

    private func setUpBlockerCell(_ tableView: UITableView) {
        let nib = UINib(nibName: blockedCellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: blockedCellReuseIdentifier)
    }

    private func setUpGapMarkerCell(_ tableView: UITableView) {
        let nib = UINib(nibName: gapMarkerCellNibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: gapMarkerCellReuseIdentifier)
    }

    func estimatedRowHeight() -> CGFloat {
        return rowHeight
    }

    func crossPostCell(_ tableView: UITableView) -> ReaderCrossPostCell {
        tableView.dequeueReusableCell(withIdentifier: crossPostCellReuseIdentifier) as! ReaderCrossPostCell
    }

    func postCell(in tableView: UITableView, for indexPath: IndexPath) -> ReaderPostCell {
        tableView.dequeueReusableCell(withIdentifier: postCellReuseIdentifier, for: indexPath) as! ReaderPostCell
    }

    func gapMarkerCell(_ tableView: UITableView) -> ReaderGapMarkerCell {
        tableView.dequeueReusableCell(withIdentifier: gapMarkerCellReuseIdentifier) as! ReaderGapMarkerCell
    }

    func blockedSiteCell(_ tableView: UITableView) -> ReaderBlockedSiteCell {
        tableView.dequeueReusableCell(withIdentifier: blockedCellReuseIdentifier) as! ReaderBlockedSiteCell
    }
}

import UIKit

/// This cell type displays data rows for Site Stats Details (SiteStatsDetailTableViewController).
/// Ex: Period Post and Pages.
/// It adds a StatsTotalRow to the cell, and utilizes its functionality for row selection.
/// If a row is selected, StatsTotalRowDelegate is informed to display the associated detail.
///

class DetailDataCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    private weak var detailsDelegate: SiteStatsDetailsDelegate?
    private var rowData: StatsTotalRowData?

    // MARK: - Configure

    func configure(rowData: StatsTotalRowData,
                   detailsDelegate: SiteStatsDetailsDelegate?,
                   hideSeparator: Bool = false) {

        self.rowData = rowData
        self.detailsDelegate = detailsDelegate

        let row = StatsTotalRow.loadFromNib()
        row.configure(rowData: rowData, delegate: self)
        row.showSeparator = !hideSeparator

        contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(row)
    }

}

// MARK: - StatsTotalRowDelegate

extension DetailDataCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        detailsDelegate?.displayWebViewWithURL?(url)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        detailsDelegate?.showPostStats?(postID: postID, postTitle: postTitle, postURL: postURL)
    }

}

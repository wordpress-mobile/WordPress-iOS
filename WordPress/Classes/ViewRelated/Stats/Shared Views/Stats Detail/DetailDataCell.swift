import UIKit

/// This cell type displays data rows for Site Stats Details (SiteStatsDetailTableViewController).
/// Ex: Period Post and Pages.
/// It adds a StatsTotalRow to the cell, and utilizes its functionality for row selection.
/// If a row is selected, StatsTotalRowDelegate is informed to display the associated detail.
///

class DetailDataCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dataView: UIView!

    // Line shown at the bottom of the view, spanning the entire width.
    // It is shown on the last child row of an expanded row.
    // Used to indicate the bottom of the expanded rows section. Hidden by default.
    @IBOutlet weak var bottomExpandedSeparatorLine: UIView!

    private weak var detailsDelegate: SiteStatsDetailsDelegate?
    private var rowData: StatsTotalRowData?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(rowData: StatsTotalRowData,
                   detailsDelegate: SiteStatsDetailsDelegate?,
                   hideSeparator: Bool = false,
                   expanded: Bool = false,
                   isChildRow: Bool = false) {

        Style.configureViewAsSeparator(bottomExpandedSeparatorLine)

        self.rowData = rowData
        self.detailsDelegate = detailsDelegate

        let row = StatsTotalRow.loadFromNib()
        row.configure(rowData: rowData, delegate: self)

        if expanded {
            // If the row is expanded, the separators are set accordingly.
            row.expanded = expanded
        }
        else {
            // If this is a child row, don't show the the indented separator.
            // Instead, toggle this cell's full width separator line.
            row.showSeparator = isChildRow ? false : !hideSeparator
            bottomExpandedSeparatorLine.isHidden = isChildRow ? hideSeparator : true

            if isChildRow {
                Style.configureLabelAsChildRowTitle(row.itemLabel)
            }
        }

        dataView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        dataView.pinSubviewToAllEdges(row)
    }

}

// MARK: - StatsTotalRowDelegate

extension DetailDataCell: StatsTotalRowDelegate {

    func displayMediaWithID(_ mediaID: NSNumber) {
        detailsDelegate?.displayMediaWithID?(mediaID)
    }

    func displayWebViewWithURL(_ url: URL) {
        detailsDelegate?.displayWebViewWithURL?(url)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        detailsDelegate?.showPostStats?(postID: postID, postTitle: postTitle, postURL: postURL)
    }

    func toggleChildRowsForRow(_ row: StatsTotalRow) {
        detailsDelegate?.toggleChildRowsForRow?(row)
    }

}

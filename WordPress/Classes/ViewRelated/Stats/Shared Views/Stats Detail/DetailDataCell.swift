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
                   hideIndentedSeparator: Bool = false,
                   hideFullSeparator: Bool = true,
                   expanded: Bool = false,
                   isChildRow: Bool = false,
                   showChildRowImage: Bool = true) {

        Style.configureViewAsSeparator(bottomExpandedSeparatorLine)

        self.rowData = rowData
        self.detailsDelegate = detailsDelegate

        let row = StatsTotalRow.loadFromNib()
        row.configure(rowData: rowData, delegate: self, forDetails: true)

        bottomExpandedSeparatorLine.isHidden = hideFullSeparator

        if expanded {
            // If the row is expanded, the row's separators are set accordingly.
            row.expanded = expanded
        }
        else {
            row.showSeparator = !hideIndentedSeparator
        }

        if isChildRow {
            Style.configureLabelAsChildRowTitle(row.itemLabel)
            row.imageView.isHidden = !showChildRowImage
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

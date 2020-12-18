import Foundation

extension ReaderStreamViewController {
    /// Show ghost card cells at the top of the tableView
    func showGhost() {
        guard ghostableTableView.superview == nil else {
            return
        }

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ghostableTableView)
        NSLayoutConstraint.activate([
            ghostableTableView.widthAnchor.constraint(equalTo: tableView.widthAnchor, multiplier: 1),
            ghostableTableView.heightAnchor.constraint(equalTo: tableView.heightAnchor, multiplier: 1),
            ghostableTableView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ghostableTableView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])

        ghostableTableView.separatorStyle = .none

        let postCardTextCellNib = UINib(nibName: "ReaderPostCardCell", bundle: Bundle.main)
        ghostableTableView.register(postCardTextCellNib, forCellReuseIdentifier: "ReaderPostCardCell")

        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: "ReaderPostCardCell", rowsPerSection: [10])
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        ghostableTableView.estimatedRowHeight = 200
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: ghostOptions, style: style)
        ghostableTableView.isScrollEnabled = false
        ghostableTableView.isHidden = false
    }

    /// Hide the ghost card cells
    func hideGhost() {
        ghostableTableView.removeGhostContent()
        ghostableTableView.removeFromSuperview()
    }
}

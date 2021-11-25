/// Table View delegate to handle the Comments table displayed in Reader Post details.
///
class ReaderDetailCommentsTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Public Properties

    var comments: [Comment] = [] {
        didSet {
            // Add one for the button row.
            totalRows = comments.count + 1
        }
    }

    var totalComments = 0
    weak var buttonDelegate: BorderedButtonTableViewCellDelegate?

    // MARK: - Private Properties

    private var totalRows = 0

    // MARK: - Table Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == (totalRows - 1) {
            return showCommentsButtonCell()
        }

        return UITableViewCell()
    }

}

private extension ReaderDetailCommentsTableViewDelegate {

    func showCommentsButtonCell() -> BorderedButtonTableViewCell {
        let title = NSLocalizedString("View All Comments", comment: "Title for button on the post details page to show all comments when tapped.")
        let cell = BorderedButtonTableViewCell()
        cell.configure(buttonTitle: title)
        cell.delegate = buttonDelegate
        return cell
    }

}

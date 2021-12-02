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

        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentContentTableViewCell.defaultReuseID) as? CommentContentTableViewCell,
              let comment = comments[safe: indexPath.row] else {
                  return UITableViewCell()
              }

        cell.configure(with: comment) { _ in
            tableView.performBatchUpdates({})
        }

        cell.hideAllActions()
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReaderDetailCommentsHeader.defaultReuseID) as? ReaderDetailCommentsHeader else {
            return nil
        }

        let titleFormat = totalComments == 1 ? Constants.singularCommentFormat : Constants.pluralCommentsFormat
        header.titleLabel.text = String(format: titleFormat, totalComments)
        header.addBottomBorder(withColor: .divider)
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return ReaderDetailCommentsHeader.estimatedHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

}

private extension ReaderDetailCommentsTableViewDelegate {

    func showCommentsButtonCell() -> BorderedButtonTableViewCell {
        let cell = BorderedButtonTableViewCell()
        cell.configure(buttonTitle: Constants.buttonTitle, borderColor: .textTertiary, buttonInsets: Constants.buttonInsets)
        cell.delegate = buttonDelegate
        return cell
    }

    struct Constants {
        static let buttonTitle = NSLocalizedString("View All Comments", comment: "Title for button on the post details page to show all comments when tapped.")
        static let singularCommentFormat = NSLocalizedString("%1$d Comment", comment: "Singular label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let pluralCommentsFormat = NSLocalizedString("%1$d Comments", comment: "Plural label displaying number of comments. %1$d is a placeholder for the number of Comments.")
        static let buttonInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
}

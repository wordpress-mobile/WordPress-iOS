import Foundation


class EditCommentTableViewController: UITableViewController {

    // MARK: - Properties

    private let sectionHeaders =
        [NSLocalizedString("Name", comment: "Header for a comment author's name, shown when editing a comment.").localizedUppercase,
         NSLocalizedString("Comment", comment: "Header for a comment's content, shown when editing a comment.").localizedUppercase,
         NSLocalizedString("Web Address", comment: "Header for a comment author's web address, shown when editing a comment.").localizedUppercase,
         NSLocalizedString("Email Address", comment: "Header for a comment author's email address, shown when editing a comment.").localizedUppercase]

    // MARK: - Init

    required convenience init() {
        self.init(style: .insetGrouped)
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
    }

    // MARK: - UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaders.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[safe: section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: return custom cell
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Make sure no SectionFooter is rendered
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Make sure no SectionFooter is rendered
        return nil
    }

}

private extension EditCommentTableViewController {

    // MARK: - View Config

    func setupNavBar() {
        title = NSLocalizedString("Edit Comment", comment: "View title when editing a comment.")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
    }

    // MARK: - Nav bar button actions

    @objc func cancelButtonTapped(sender: UIBarButtonItem) {
        // TODO: discard changes
        dismiss(animated: true)
    }

    @objc func doneButtonTapped(sender: UIBarButtonItem) {
        // TODO: save changes
        dismiss(animated: true)
    }

}

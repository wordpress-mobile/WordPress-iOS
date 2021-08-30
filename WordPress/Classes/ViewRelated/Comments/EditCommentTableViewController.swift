import Foundation


class EditCommentTableViewController: UITableViewController {

    // MARK: - Properties

    private let comment: Comment

    private var updatedName: String?
    private var updatedWebAddress: String?
    private var updatedEmailAddress: String?
    private var updatedContent: String?

    private var isEmailValid = true
    private var isUrlValid = true

    // If the textView cell is recreated via dequeueReusableCell,
    // the cursor location is lost when the cell is scrolled off screen.
    // So save and use one instance of the cell.
    private let commentContentCell = EditCommentMultiLineCell.loadFromNib()

    // MARK: - Init

    @objc required init(comment: Comment) {
        self.comment = comment
        updatedName = comment.author
        updatedWebAddress = comment.author_url
        updatedEmailAddress = comment.author_email
        updatedContent = comment.contentForEdit()
        super.init(style: .insetGrouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCommentContentCell()
        setupTableView()
        setupNavBar()
        addDismissKeyboardTapGesture()
    }

    // MARK: - UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableSections.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return TableSections(rawValue: section)?.header
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableSection = TableSections(rawValue: indexPath.section) else {
            DDLogError("Edit Comment: invalid table section.")
            return UITableViewCell()
        }

        // Comment content cell
        if tableSection == TableSections.comment {
            return commentContentCell
        }

        // All other cells
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EditCommentSingleLineCell.defaultReuseID) as? EditCommentSingleLineCell else {
            return UITableViewCell()
        }

        switch tableSection {
        case TableSections.name:
            cell.configure(text: comment.author)
        case TableSections.webAddress:
            cell.configure(text: comment.author_url, style: .url)
        case TableSections.emailAddress:
            cell.configure(text: comment.author_email, style: .email)
        default:
            DDLogError("Edit Comment: unsupported table section.")
            break
        }

        cell.delegate = self
        return cell
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

// MARK: - Private Extension

private extension EditCommentTableViewController {

    // MARK: - View config

    func setupTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true

        tableView.register(EditCommentSingleLineCell.defaultNib,
                           forCellReuseIdentifier: EditCommentSingleLineCell.defaultReuseID)

        tableView.register(EditCommentMultiLineCell.defaultNib,
                           forCellReuseIdentifier: EditCommentMultiLineCell.defaultReuseID)
    }

    func configureCommentContentCell() {
        commentContentCell.configure(text: comment.contentForEdit())
        commentContentCell.delegate = self
    }

    func setupNavBar() {
        title = NSLocalizedString("Edit Comment", comment: "View title when editing a comment.")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        updateDoneButton()
    }

    func addDismissKeyboardTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
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

    // MARK: - Tap gesture handling

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Table sections

    private enum TableSections: Int, CaseIterable {
        // The case order dictates the table row order.
        case name
        case webAddress
        case emailAddress
        case comment

        var header: String {
            switch self {
            case .name:
                return NSLocalizedString("Name", comment: "Header for a comment author's name, shown when editing a comment.").localizedUppercase
            case .webAddress:
                return NSLocalizedString("Web Address", comment: "Header for a comment author's web address, shown when editing a comment.").localizedUppercase
            case .emailAddress:
                return NSLocalizedString("Email Address", comment: "Header for a comment author's email address, shown when editing a comment.").localizedUppercase
            case .comment:
                return NSLocalizedString("Comment", comment: "Header for a comment's content, shown when editing a comment.").localizedUppercase
            }
        }
    }

    // MARK: - Helpers

    func updateDoneButton() {
        navigationItem.rightBarButtonItem?.isEnabled = commentHasChanged() && isEmailValid && isUrlValid
    }

    func commentHasChanged() -> Bool {
        return comment.author != updatedName ||
            comment.author_email != updatedEmailAddress ||
            comment.author_url != updatedWebAddress ||
            comment.contentForEdit() != updatedContent
    }

}

extension EditCommentTableViewController: EditCommentSingleLineCellDelegate {

    func fieldUpdated(_ type: TextFieldStyle, updatedText: String?, isValid: Bool) {
        switch type {
        case .text:
            updatedName = updatedText?.trim()
        case .email:
            updatedEmailAddress = updatedText?.trim()
            isEmailValid = {
                if updatedEmailAddress == nil || updatedEmailAddress?.isEmpty == true {
                    return true
                }
                return isValid
            }()
        case .url:
            updatedWebAddress = updatedText?.trim()
            isUrlValid = isValid
        }

        updateDoneButton()
    }

}

extension EditCommentTableViewController: EditCommentMultiLineCellDelegate {

    func textViewHeightUpdated() {
        tableView.beginUpdates()
        tableView.scrollToRow(at: IndexPath(row: 0, section: TableSections.comment.rawValue), at: .bottom, animated: false)
        tableView.endUpdates()
    }

}

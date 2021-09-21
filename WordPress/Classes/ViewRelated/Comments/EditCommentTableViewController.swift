import Foundation


class EditCommentTableViewController: UITableViewController {

    // MARK: - Properties

    private let comment: Comment

    private var updatedName: String?
    private var updatedWebAddress: String?
    private var updatedEmailAddress: String?
    private var updatedContent: String?

    private var isEmailValid = true

    // If the textView cell is recreated via dequeueReusableCell,
    // the cursor location is lost when the cell is scrolled off screen.
    // So save and use one instance of the cell.
    private let commentContentCell = InlineEditableMultiLineCell.loadFromNib()

    // A closure executed when the view is dismissed.
    // Returns the Comment object and a Bool indicating if the Comment has been changed.
    @objc var completion: ((Comment, Bool) -> Void)?

    // MARK: - Init

    convenience init(comment: Comment, completion: ((Comment, Bool) -> Void)? = nil) {
        self.init(comment: comment)
        self.completion = completion
    }

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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InlineEditableSingleLineCell.defaultReuseID) as? InlineEditableSingleLineCell else {
            return UITableViewCell()
        }

        switch tableSection {
        case TableSections.name:
            cell.configure(text: updatedName)
        case TableSections.webAddress:
            cell.configure(text: updatedWebAddress, style: .url)
        case TableSections.emailAddress:
            cell.configure(text: updatedEmailAddress, style: .email)
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

        tableView.register(InlineEditableSingleLineCell.defaultNib,
                           forCellReuseIdentifier: InlineEditableSingleLineCell.defaultReuseID)

        tableView.register(InlineEditableMultiLineCell.defaultNib,
                           forCellReuseIdentifier: InlineEditableMultiLineCell.defaultReuseID)
    }

    func configureCommentContentCell() {
        commentContentCell.configure(text: updatedContent)
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
        guard commentHasChanged() else {
            finishWithoutUpdates()
            return
        }

        showConfirmationAlert()
    }

    @objc func doneButtonTapped(sender: UIBarButtonItem) {
        finishWithUpdates()
    }

    // MARK: - Tap gesture handling

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - View dismissal handling

    func finishWithUpdates() {
        comment.author = updatedName ?? ""
        comment.author_url = updatedWebAddress ?? ""
        comment.author_email = updatedEmailAddress ?? ""
        comment.content = updatedContent ?? ""
        completion?(comment, true)
        dismiss(animated: true)
    }


    func finishWithoutUpdates() {
        completion?(comment, false)
        dismiss(animated: true)
    }

    func showConfirmationAlert() {
        let title = NSLocalizedString("You have unsaved changes.", comment: "Title of message with options that shown when there are unsaved changes and the author cancelled editing a Comment.")
        let discardTitle = NSLocalizedString("Discard", comment: "Button shown if there are unsaved changes and the author cancelled editing a Comment.")
        let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Button shown if there are unsaved changes and the author cancelled editing a Comment.")

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(keepEditingTitle)

        alertController.addDestructiveActionWithTitle(discardTitle) { [weak self] action in
            self?.finishWithoutUpdates()
        }

        alertController.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Helpers

    func updateDoneButton() {
        navigationItem.rightBarButtonItem?.isEnabled = commentHasChanged() && isEmailValid
    }

    func commentHasChanged() -> Bool {
        return comment.author != updatedName ||
            comment.author_email != updatedEmailAddress ||
            comment.author_url != updatedWebAddress ||
            comment.contentForEdit() != updatedContent
    }

    // MARK: - Table sections

    enum TableSections: Int, CaseIterable {
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

}

extension EditCommentTableViewController: InlineEditableSingleLineCellDelegate {

    func textUpdatedForCell(_ cell: InlineEditableSingleLineCell) {
        let updatedText = cell.textField.text?.trim()

        switch cell.textFieldStyle {
        case .text:
            updatedName = updatedText
        case .url:
            updatedWebAddress = updatedText
        case .email:
            updatedEmailAddress = updatedText
            isEmailValid = {
                if updatedEmailAddress == nil || updatedEmailAddress?.isEmpty == true {
                    return true
                }
                return cell.isValid
            }()
            cell.showInvalidState(!isEmailValid)
        }

        updateDoneButton()
    }

}

extension EditCommentTableViewController: InlineEditableMultiLineCellDelegate {

    func textViewHeightUpdatedForCell(_ cell: InlineEditableMultiLineCell) {
        tableView.performBatchUpdates({})
    }

    func textUpdatedForCell(_ cell: InlineEditableMultiLineCell) {
        updatedContent = cell.textView.text.trim()
        updateDoneButton()
    }

}

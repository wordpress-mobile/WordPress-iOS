import UIKit

/// Types the closures than can be provided as completion blocks
typealias SettingsTitleSubtitleAction = ((SettingsTitleSubtitleController.Content) -> Void)


/**
 Presents a view controller with a textfiled and a textview, that can be used to create / edit a title and subtitle pair.
*/
final class SettingsTitleSubtitleController: UITableViewController {

    /// The content to be presented on screen (i.e. title and subtitle).
    final class Content {
        var title: String?
        var subtitle: String?
        var titleHeader: String?
        var subtitleHeader: String?
        var titleErrorFooter: String?

        init(title: String?, subtitle: String?, titleHeader: String? = nil, subtitleHeader: String? = nil, titleErrorFooter: String? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.titleHeader = titleHeader
            self.subtitleHeader = subtitleHeader
            self.titleErrorFooter = titleErrorFooter
        }
    }


    /// String literals to be presented in an action confirmation alert
    struct Confirmation {
        let title: String
        let subtitle: String
        let actionTitle: String
        let cancelTitle: String
        let icon: UIImage
        let isDestructiveAction: Bool
    }

    fileprivate enum Sections: Int {
        case name
        case description

        static let count: Int = {
            var returnValue: Int = 0
            while let _ = Sections(rawValue: returnValue) {
                returnValue = returnValue + 1
            }
            return returnValue
        }()

        static func section(for index: Int) -> Sections {
            guard index < count else {
                return .name
            }
            return Sections(rawValue: index)!
        }

        var height: CGFloat {
            switch self {
            case .name:
                return WPTableViewDefaultRowHeight
            case .description:
                return WPTableViewDefaultRowHeight * 3
            }
        }

    }

    private lazy var nameCell: WPTableViewCell = {
        return makeCell(content: nameTextField)
    }()

    private lazy var descriptionCell: WPTableViewCell = {
        return makeCell(content: descriptionTextView)
    }()

    private lazy var nameTextField: UITextField = {
        return makeTextField()
    }()

    private lazy var descriptionTextView: UITextView = {
        return makeTextView()
    }()

    private let content: SettingsTitleSubtitleController.Content
    private let confirmation: SettingsTitleSubtitleController.Confirmation?

    private var action: SettingsTitleSubtitleAction?
    private var update: SettingsTitleSubtitleAction?
    private var isTriggeringAction = false

    public init(content: SettingsTitleSubtitleController.Content, confirmation: SettingsTitleSubtitleController.Confirmation? = nil) {
        self.content = content
        self.confirmation = confirmation
        super.init(style: .grouped)
    }


    /// Closure to be executed when the right bar button item is tapped. If there was a Confirmation passed in this VC's constructor, this closure will be called only after users confirm an alert.
    ///
    func setAction(_ closure: @escaping SettingsTitleSubtitleAction) {
        action = closure
    }


    /// Closure to be executed when the users tap the Back button, only if there is valid text in the Title textfield
    ///
    func setUpdate(_ closure: @escaping SettingsTitleSubtitleAction) {
        update = closure
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setupNavigationBar()
        setupTitle()
        setupTable()
        nameTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        validateData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isTriggeringAction = false
    }

    private func setupNavigationBar() {
        guard let title = content.title, title.count > 0 else {
            return
        }

        navigationItem.rightBarButtonItem = actionButton()
    }

    private func actionButton() -> UIBarButtonItem {
        let trashIcon = confirmation?.icon
        return UIBarButtonItem(image: trashIcon, style: .plain, target: self, action: #selector(actionButtonTapped))
    }

    private func setupTitle() {
        navigationItem.title = content.title
    }

    private func setupTable() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.tableFooterView = UIView(frame: .zero)
    }

    private func makeCell(content: UIView) -> WPTableViewCell {
        let cell = WPTableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.contentView.addSubview(content)

        let readableGuide = cell.contentView.readableContentGuide
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: readableGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: readableGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: readableGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: readableGuide.bottomAnchor)
            ])

        WPStyleGuide.configureTableViewActionCell(cell)
        return cell
    }

    private func makeTextField() -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.clearButtonMode = .whileEditing
        textField.font = WPStyleGuide.tableviewTextFont()
        textField.textColor = .text
        textField.delegate = self
        textField.returnKeyType = .done

        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        return textField
    }

    private func makeTextView() -> UITextView {
        let textView = UITextView(frame: .zero, textContainer: nil)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = WPStyleGuide.tableviewTextFont()
        textView.textColor = .text
        textView.backgroundColor = .listForeground
        textView.delegate = self
        textView.returnKeyType = .done

        // Remove leading and trailing padding, so textview content aligns
        // with title textfield content.
        let padding = textView.textContainer.lineFragmentPadding
        textView.textContainer.lineFragmentPadding = 0

        // Inset the trailing edge so the scroll indicator doesn't obscure text
        textView.textContainerInset.right = padding

        return textView
    }

    @objc private func actionButtonTapped() {
        guard let confirmation = confirmation else {
            executeAction()
            return
        }

        let title =  confirmation.title
        let message = confirmation.subtitle
        let actionTitle = confirmation.actionTitle
        let cancelTitle = confirmation.cancelTitle

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(cancelTitle)
        if confirmation.isDestructiveAction {
            alertController.addDestructiveActionWithTitle(actionTitle) { _ in
                self.executeAction()
            }
        } else {
            alertController.addDefaultActionWithTitle(actionTitle) { _ in
                self.executeAction()
            }
        }
        alertController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(alertController, animated: true)
    }

    private func executeAction() {
        isTriggeringAction = true
        action?(content)
    }

    private func validateData() {
        guard let name = content.title, name.count > 0 else {
            return
        }

        guard isTriggeringAction == false else {
            return
        }

        update?(content)
    }
}

// MARK: - Table view datasource
extension SettingsTitleSubtitleController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let contentSection = Sections.section(for: section)
        return titleForHeader(section: contentSection)
    }

    private func titleForHeader(section: Sections) -> String? {
        switch section {
        case .name:
            return content.titleHeader?.localizedUppercase
        case .description:
            return content.subtitleHeader?.localizedUppercase
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let contentSection = Sections.section(for: section)
        switch contentSection {
        case .name:
            return content.titleErrorFooter
        case .description:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let contentSection = Sections.section(for: section)
        if contentSection == .name {
            if let footer = view as? UITableViewHeaderFooterView {
                footer.textLabel?.textColor = .error
            }
            // By default the footer is hidden, it will be shown if the user leaves the title empty
            view.isHidden = true
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        switch sectionForIndexPath {
        case .name:
            nameTextField.text = content.title
            return nameCell
        case .description:
            descriptionTextView.text = content.subtitle
            return descriptionCell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        return sectionForIndexPath.height
    }
}

// MARK: - Tag title updates
extension SettingsTitleSubtitleController {
    @objc
    fileprivate func textChanged(_ textField: UITextField) {
        content.title = textField.text?.trim()
        setupTitle()
        if let title = content.title {
            tableView.footerView(forSection: Sections.name.rawValue)?.isHidden = title.count > 0
        }
    }
}

// MARK: - UITextViewDelegate
extension SettingsTitleSubtitleController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        content.subtitle = textView.text
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == descriptionTextView &&
           text == "\n" {
            descriptionTextView.resignFirstResponder()
            navigationController?.popViewController(animated: true)
        }
        return true
    }
}

// MARK: - UITextFieldDelegate
extension SettingsTitleSubtitleController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            nameTextField.resignFirstResponder()
            descriptionTextView.becomeFirstResponder()
            return false
        }
        return true
    }
}

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

        init(title: String?, subtitle: String?, titleHeader: String? = nil, subtitleHeader: String? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.titleHeader = titleHeader
            self.subtitleHeader = subtitleHeader
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
        return self.cell(content: self.nameTextField)
    }()

    private lazy var descriptionCell: WPTableViewCell = {
        return self.cell(content: self.descriptionTextField)
    }()

    private lazy var nameTextField: UITextField = {
        return self.textField()
    }()

    private lazy var descriptionTextField: UITextView = {
        return self.textView()
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
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.tableFooterView = UIView(frame: .zero)
    }

    private func cell(content: UIView) -> WPTableViewCell {
        let returnValue = WPTableViewCell(style: .default, reuseIdentifier: nil)
        returnValue.selectionStyle = .none
        returnValue.contentView.addSubview(content)

        let readableGuide = returnValue.contentView.readableContentGuide
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: readableGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: readableGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: readableGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: readableGuide.bottomAnchor)
            ])

        WPStyleGuide.configureTableViewActionCell(returnValue)
        return returnValue
    }

    private func textField() -> UITextField {
        let returnValue = UITextField(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.clearButtonMode = .whileEditing
        returnValue.font = WPStyleGuide.tableviewTextFont()
        returnValue.textColor = WPStyleGuide.darkGrey()
        returnValue.returnKeyType = .done
        returnValue.keyboardType = .default

        returnValue.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        return returnValue
    }

    private func textView() -> UITextView {
        let returnValue = UITextView(frame: .zero, textContainer: nil)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.font = WPStyleGuide.tableviewTextFont()
        returnValue.textColor = WPStyleGuide.darkGrey()
        returnValue.delegate = self

        return returnValue
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
        present(alertController, animated: true, completion: nil)
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        switch sectionForIndexPath {
        case .name:
            nameTextField.text = content.title
            return nameCell
        case .description:
            descriptionTextField.text = content.subtitle
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
        content.title = textField.text
        setupTitle()
    }
}

// MARK: - Tag subtitle updates
extension SettingsTitleSubtitleController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        content.subtitle = textView.text
    }
}

import UIKit
import Gridicons

final class SettingsTitleDescriptionController: UITableViewController {
    private let tag: PostTag
    final class Data {
        var title: String?
        var extendedDescription: String?
    }

    fileprivate enum Sections: Int, CustomStringConvertible {
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

        var description: String {
            switch self {
            case .name:
                return NSLocalizedString("Tag", comment: "Section header for tag name in Tag Details View.").uppercased()
            case .description:
                return NSLocalizedString("Description", comment: "Section header for tag name in Tag Details View.").uppercased()
            }
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

    public init(tag: PostTag) {
        self.tag = tag
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setupNavigationBar()
        setupTitle()
        setupTable()
    }

    private func setupNavigationBar() {
        guard let name = tag.name, name.count > 0 else {
            return
        }

        navigationItem.rightBarButtonItem = deleteButton()
    }

    private func deleteButton() -> UIBarButtonItem {
        let trashIcon = Gridicon.iconOfType(.trash)
        return UIBarButtonItem(image: trashIcon, style: .plain, target: self, action: #selector(deleteTag))
    }

    private func setupTitle() {
        navigationItem.title = tag.name
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

        return returnValue
    }

    private func textField() -> UITextField {
        let returnValue = UITextField(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
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

    @objc private func deleteTag() {
        let title =  NSLocalizedString("Delete this tag", comment: "Delete Tag confirmation action title")
        let message = NSLocalizedString("Are you sure you want to delete this tag?", comment: "Message asking for confirmation on tag deletion")
        let actionTitle = NSLocalizedString("Delete", comment: "Delete")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(cancelTitle)
        alertController.addDefaultActionWithTitle(actionTitle) { _ in
//            let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
//            tagsService.delete(self.tag, for: self.blog)
            self.navigateBack()
        }
    }

    private func navigateBack() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table view datasource
extension SettingsTitleDescriptionController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Sections.section(for: section).description
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        switch sectionForIndexPath {
        case .name:
            nameTextField.text = tag.name
            return nameCell
        case .description:
            descriptionTextField.text = tag.tagDescription
            return descriptionCell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        return sectionForIndexPath.height
    }
}


// MARK: - Tag name updates
extension SettingsTitleDescriptionController {
    @objc
    fileprivate func textChanged(_ textField: UITextField) {
        tag.name = textField.text
        setupTitle()
    }
}


// MARK: - Tag description updates
extension SettingsTitleDescriptionController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        tag.tagDescription = textView.text
    }
}

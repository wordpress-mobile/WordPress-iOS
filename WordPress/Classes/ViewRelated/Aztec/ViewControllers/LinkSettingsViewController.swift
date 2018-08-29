import UIKit

struct LinkSettings {
    var  url: String = ""
    var  text: String = ""
    var  openInNewWindow: Bool = false
    var  isNewLink: Bool = true

    init() {

    }

    init(url: String, text: String, openInNewWindow: Bool, isNewLink: Bool = true) {
        self.url = url
        self.text = text
        self.openInNewWindow = openInNewWindow
        self.isNewLink = isNewLink
    }
}

enum LinkAction {
    case insert
    case update
    case remove
    case cancel
}

class LinkSettingsViewController: UITableViewController {

    private var linkSettings =  LinkSettings()
    private var viewModel: ImmuTable!
    private var viewHandler: ImmuTableViewHandler!

    typealias LinkCallback = (_ action: LinkAction, _ settings: LinkSettings) -> ()

    private var callback: LinkCallback?

    init(settings: LinkSettings, callback: @escaping LinkCallback) {
        linkSettings = settings
        self.callback = callback
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        linkSettings = LinkSettings()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewHandler = ImmuTableViewHandler(takeOver: self)
        setupNavigation()
        setupViewModel()
        updateNavigation()
    }

    private func setupNavigation() {
        title = NSLocalizedString("Link Settings", comment: "Noun. Title for screen in editor that allows to configure link options")
        let insertTitle = NSLocalizedString("Insert", comment: "Label action for inserting a link on the editor")
        let updateTitle = NSLocalizedString("Update", comment: "Label action for updating a link on the editor")

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelChanges))

        if linkSettings.isNewLink {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: insertTitle, style: .done, target: self, action: #selector(insertLink))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: updateTitle, style: .done, target: self, action: #selector(updateLink))
        }
    }

    private func setupViewModel() {
        ImmuTable.registerRows([EditableTextRow.self, SwitchRow.self, DestructiveButtonRow.self], tableView: tableView)

        let urlRow = EditableTextRow(title: NSLocalizedString("URL", comment: "URL text field placeholder"),
                                     value: linkSettings.url,
                                     action: editURL)
        let textRow = EditableTextRow(title: NSLocalizedString("Link Text", comment: "Noun. Label for the text of a link in the editor"),
                                      value: linkSettings.text,
                                      action: editTitle)
        let openInNewWindowRow = SwitchRow(title: NSLocalizedString("Open in a new Window/Tab", comment: "Label for the description of openening a link using a new window"),
                                           value: linkSettings.openInNewWindow,
                                           onChange: editOpenInNewWindow)

        let removeLinkRow = DestructiveButtonRow(title: NSLocalizedString("Remove Link", comment: "Label action for removing a link from the editor"),
                                              action: removeLink,
                                              accessibilityIdentifier: "RemoveLink")

        let editSection = ImmuTableSection(rows: [urlRow, textRow, openInNewWindowRow])
        var sections = [editSection]
        if !linkSettings.isNewLink {
            sections.append(ImmuTableSection(rows: [removeLinkRow]))
        }
        viewModel = ImmuTable(sections: sections)
        viewHandler.viewModel = viewModel
    }

    private func reloadViewModel() {
        setupViewModel()
        updateNavigation()
        tableView.reloadData()
    }

    private func updateNavigation() {
        self.navigationItem.rightBarButtonItem!.isEnabled = !self.linkSettings.url.isEmpty
    }

    private func editURL(row: ImmuTableRow) {
        let editableRow = row as! EditableTextRow
        pushSettingsController(for: editableRow, hint: nil,
                               onValueChanged: { [weak self] value in
                                self?.linkSettings.url  = value
                                self?.reloadViewModel()
        }, mode: .URL)
    }

    private func editTitle(row: ImmuTableRow) {
        let editableRow = row as! EditableTextRow
        pushSettingsController(for: editableRow, hint: nil,
                               onValueChanged: { [weak self] value in
                                self?.linkSettings.text  = value
                                self?.reloadViewModel()
        })
    }

    private func editOpenInNewWindow(value: Bool) {
        linkSettings.openInNewWindow = value
    }

    private func removeLink(row: ImmuTableRow) {
        callback?(.remove, linkSettings)
    }

    private func pushSettingsController(for row: EditableTextRow, hint: String? = nil, onValueChanged: @escaping SettingsTextChanged, mode: SettingsTextModes = .text) {
        let title = row.title
        let value = row.value
        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.onValueChanged = onValueChanged
        controller.mode = mode

        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: Actions

    @objc private func insertLink() {
        callback?(.insert, linkSettings)
    }

    @objc private func updateLink() {
        callback?(.update, linkSettings)
    }

    @objc private func cancelChanges() {
        callback?(.cancel, linkSettings)
    }
}

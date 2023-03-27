import UIKit

class RemoteConfigDebugViewController: UITableViewController {

    private var handler: ImmuTableViewHandler!

    override init(style: UITableView.Style) {
        super.init(style: style)

        title = Strings.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            CheckmarkRow.self
        ], tableView: tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func reloadViewModel() {
        let rows = RemoteConfigParameter.allCases.map({ makeRemoteConfigParamRow(for: $0) })

        handler.viewModel = ImmuTable(sections: [
            ImmuTableSection(rows: rows, footerText: Strings.footer)
        ])
    }

    private func makeRemoteConfigParamRow(for param: RemoteConfigParameter) -> ImmuTableRow {
        let remoteConfigStore = RemoteConfigStore()
        let overrideStore = RemoteConfigOverrideStore()
        var overriddenValueText: String?
        var currentValueText: String
        var placeholderText: String
        var isOverridden = false

        if let originalValue = param.originalValue(using: remoteConfigStore) {
            placeholderText = String(describing: originalValue)
            currentValueText = String(describing: originalValue)
        }
        else {
            placeholderText = Strings.defaultPlaceholder
            currentValueText = "nil"
        }

        if let overriddenValue = overrideStore.overriddenValue(for: param) {
            overriddenValueText = String(describing: overriddenValue)
            currentValueText = String(describing: overriddenValue)
            isOverridden = true
        }

        return CheckmarkRow(title: param.description, subtitle: currentValueText, checked: isOverridden) { row in
            let textViewController = SettingsTextViewController(text: overriddenValueText, placeholder: placeholderText, hint: Strings.hint)
            textViewController.title = param.description
            textViewController.onAttributedValueChanged = { [weak self] newValue in
                if newValue.string.isEmpty {
                    overrideStore.reset(param)
                } else {
                    overrideStore.override(param, withValue: newValue.string)
                }
                self?.reloadViewModel()
            }

            self.navigationController?.pushViewController(textViewController, animated: true)
        }
    }

}

private extension RemoteConfigDebugViewController {
    enum Strings {
        static let title = NSLocalizedString("debugMenu.remoteConfig.title",
                                             value: "Remote Config",
                                             comment: "Remote Config debug menu title")
        static let defaultPlaceholder = NSLocalizedString("debugMenu.remoteConfig.placeholder",
                                                          value: "No remote or default value",
                                                          comment: "Placeholder for overriding remote config params")
        static let hint = NSLocalizedString("debugMenu.remoteConfig.hint",
                                                          value: "Override the chosen param by defining a new value here.",
                                                          comment: "Hint for overriding remote config params")
        static let footer = NSLocalizedString("debugMenu.remoteConfig.footer",
                                                          value: "Overridden parameters are denoted by a checkmark.",
                                                          comment: "Remote config params debug menu footer explaining the meaning of a cell with a checkmark.")
    }
}

private extension RemoteConfigParameter {
    func originalValue(using store: RemoteConfigStore = .init()) -> Any? {
        if let value = store.value(for: key) {
            return value
        }
        return defaultValue
    }
}

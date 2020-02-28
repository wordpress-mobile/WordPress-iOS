import UIKit

class DebugMenuViewController: UITableViewController {
    fileprivate var handler: ImmuTableViewHandler!

    override init(style: UITableView.Style) {
        super.init(style: style)

        title = NSLocalizedString("Debug Settings", comment: "Debug settings title")
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
            SwitchWithSubtitleRow.self
        ], tableView: tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func reloadViewModel() {
        let cases = FeatureFlag.allCases.filter({ $0.canOverride })
        let rows: [ImmuTableRow] = cases.map({ makeRow(for: $0) })

        handler.viewModel = ImmuTable(sections: [
            ImmuTableSection(headerText: Strings.featureFlags, rows: rows)
        ])
    }

    private func makeRow(for flag: FeatureFlag) -> ImmuTableRow {
        let store = FeatureFlagOverrideStore()

        let overridden: String? = store.isOverridden(flag) ? Strings.overridden : nil

        return SwitchWithSubtitleRow(title: String(describing: flag), value: flag.enabled, subtitle: overridden, onChange: { isOn in
            try? store.override(flag, withValue: isOn)
            self.reloadViewModel()
        })
    }

    enum Strings {
        static let overridden = NSLocalizedString("Overridden", comment: "Used to indicate a setting is overridden in debug builds of the app")
        static let featureFlags = NSLocalizedString("Feature flags", comment: "Title of the Feature Flags screen used in debug builds of the app")
    }
}

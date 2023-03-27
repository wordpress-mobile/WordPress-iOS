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
            EditableTextRow.self
        ], tableView: tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func reloadViewModel() {
        // TODO: To be implemented
    }

}

private extension RemoteConfigDebugViewController {
    enum Strings {
        static let title = NSLocalizedString("debugMenu.remoteConfig.title",
                                             value: "Remote Config",
                                             comment: "Remote Config debug menu title")
    }
}

import UIKit
import AutomatticTracks

class DebugMenuViewController: UITableViewController {
    private var blogService: BlogService {
        let context = ContextManager.sharedInstance().mainContext
        return BlogService(managedObjectContext: context)
    }

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
            SwitchWithSubtitleRow.self,
            ButtonRow.self
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
            ImmuTableSection(headerText: Strings.featureFlags, rows: rows),
            ImmuTableSection(headerText: Strings.tools, rows: toolsRows)
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

    // MARK: Quick Start

    private var toolsRows: [ImmuTableRow] {
        return [
            ButtonRow(title: Strings.quickStartRow, action: { [weak self] _ in
                self?.displayBlogPickerForQuickStart()
            }),
            ButtonRow(title: Strings.sendLogMessage, action: { _ in
                CrashLogging.logMessage("Debug Log Message \(UUID().uuidString)")
                self.tableView.deselectSelectedRowWithAnimationAfterDelay(true)
            }),
            ButtonRow(title: Strings.sendTestCrash, action: { _ in
                DDLogInfo("Initiating user-requested crash")
                CrashLogging.crash()
            })
        ]
    }

    private func displayBlogPickerForQuickStart() {
        let successHandler: BlogSelectorSuccessHandler = { [weak self] selectedObjectID in
            guard let blog = self?.blogService.managedObjectContext.object(with: selectedObjectID) as? Blog else {
                return
            }

            self?.dismiss(animated: true) { [weak self] in
                self?.enableQuickStart(for: blog)
            }
        }

        let selectorViewController = BlogSelectorViewController(selectedBlogObjectID: nil,
                                                                successHandler: successHandler,
                                                                dismissHandler: nil)

        selectorViewController.displaysNavigationBarWhenSearching = WPDeviceIdentification.isiPad()
        selectorViewController.dismissOnCancellation = true
        selectorViewController.displaysOnlyDefaultAccountSites = true

        let navigationController = UINavigationController(rootViewController: selectorViewController)
        present(navigationController, animated: true)
    }

    private func enableQuickStart(for blog: Blog) {
        QuickStartTourGuide.find()?.setup(for: blog)
    }

    enum Strings {
        static let overridden = NSLocalizedString("Overridden", comment: "Used to indicate a setting is overridden in debug builds of the app")
        static let featureFlags = NSLocalizedString("Feature flags", comment: "Title of the Feature Flags screen used in debug builds of the app")
        static let tools = NSLocalizedString("Tools", comment: "Title of the Tools section of the debug screen used in debug builds of the app")
        static let quickStartRow = NSLocalizedString("Enable Quick Start for Site", comment: "Title of a row displayed on the debug screen used in debug builds of the app")
        static let sendTestCrash = NSLocalizedString("Send Test Crash", comment: "Title of a row displayed on the debug screen used to crash the app and send a crash report to the crash logging provider to ensure everything is working correctly")
        static let sendLogMessage = NSLocalizedString("Send Log Message", comment: "Title of a row displayed on the debug screen used to send a pretend error message to the crash logging provider to ensure everything is working correctly")
    }
}

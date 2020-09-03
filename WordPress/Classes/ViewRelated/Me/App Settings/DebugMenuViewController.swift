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
            ImmuTableSection(headerText: Strings.tools, rows: toolsRows),
            ImmuTableSection(headerText: Strings.crashLogging, rows: crashLoggingRows),
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
            ButtonRow(title: Strings.clearCSSCache, action: { [weak self] _ in
                ReaderCSS().clearCache()
                let alert = UIAlertController(title: NSLocalizedString("Cache cleared!", comment: "Debug message informing the user that the cache for CSS in the Reader has been cleared"),
                                              message: nil, preferredStyle: .alert)
                alert.addCancelActionWithTitle(NSLocalizedString("Dismiss", comment: ""))
                self?.present(alert, animated: true, completion: nil)
                self?.tableView.deselectSelectedRowWithAnimationAfterDelay(true)
            })
        ]
    }

    private var crashLoggingRows: [ImmuTableRow] {
        return [
            ButtonRow(title: Strings.sendLogMessage, action: { _ in
                CrashLogging.logMessage("Debug Log Message \(UUID().uuidString)")
                self.tableView.deselectSelectedRowWithAnimationAfterDelay(true)
            }),
            ButtonRow(title: Strings.sendTestCrash, action: { _ in
                DDLogInfo("Initiating user-requested crash")
                CrashLogging.crash()
            }),
            ButtonRow(title: Strings.encryptedLogging, action: { _ in
                self.navigationController?.pushViewController(EncryptedLogTableViewController(), animated: true)
            }),
            SwitchWithSubtitleRow(title: Strings.alwaysSendLogs, value: shouldAlwaysSendLogs, onChange: { isOn in
                self.shouldAlwaysSendLogs = isOn
            }),
        ]
    }

    var shouldAlwaysSendLogs: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "force-crash-logging")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "force-crash-logging")
        }
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
        static let alwaysSendLogs = NSLocalizedString("Always Send Crash Logs", comment: "Title of a row displayed on the debug screen used to indicate whether crash logs should be forced to send, even if they otherwise wouldn't")
        static let crashLogging = NSLocalizedString("Crash Logging", comment: "Title of a section on the debug screen that shows a list of actions related to crash logging")
        static let encryptedLogging = NSLocalizedString("Encrypted Logs", comment: "Title of a row displayed on the debug screen used to display a screen that shows a list of encrypted logs")
        static let clearCSSCache = NSLocalizedString("Clear Reader CSS Cache", comment: "Title of a row displayed on the debug screen used to clear any cached CSS for the Reader")
    }
}

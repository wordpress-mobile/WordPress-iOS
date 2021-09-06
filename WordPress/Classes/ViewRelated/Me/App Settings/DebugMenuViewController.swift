import UIKit
import AutomatticTracks
import SwiftUI

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
            ButtonRow.self,
            EditableTextRow.self
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
            ImmuTableSection(headerText: Strings.reader, rows: readerRows),
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

    // MARK: Tools

    private var toolsRows: [ImmuTableRow] {
        var toolsRows = [
            ButtonRow(title: Strings.quickStartRow, action: { [weak self] _ in
                self?.displayBlogPickerForQuickStart()
            }),
            ButtonRow(title: Strings.sandboxStoreCookieSecretRow, action: { [weak self] _ in
                self?.displayStoreSandboxSecretInserter()
            }),
        ]

        if Feature.enabled(.weeklyRoundup) {
            toolsRows.append(ButtonRow(title: "Weekly Roundup", action: { [weak self] _ in
                self?.displayWeeklyRoundupDebugTools()
            }))
        }

        return toolsRows
    }

    // MARK: Crash Logging

    private var crashLoggingRows: [ImmuTableRow] {

        var rows: [ImmuTableRow] = [
            ButtonRow(title: Strings.sendLogMessage, action: { _ in
                WordPressAppDelegate.crashLogging?.logMessage("Debug Log Message \(UUID().uuidString)")
                self.tableView.deselectSelectedRowWithAnimationAfterDelay(true)
            }),
            ButtonRow(title: Strings.sendTestCrash, action: { _ in
                DDLogInfo("Initiating user-requested crash")
                WordPressAppDelegate.crashLogging?.crash()
            })
        ]

        if let eventLogging = WordPressAppDelegate.eventLogging {
            let tableViewController = EncryptedLogTableViewController(eventLogging: eventLogging)
            let encryptedLoggingRow = ButtonRow(title: Strings.encryptedLogging) { _ in
                self.navigationController?.pushViewController(tableViewController, animated: true)
            }
            rows.append(encryptedLoggingRow)
        }

        let alwaysSendLogsRow = SwitchWithSubtitleRow(title: Strings.alwaysSendLogs, value: UserSettings.userHasForcedCrashLoggingEnabled) { isOn in
            UserSettings.userHasForcedCrashLoggingEnabled = isOn
        }

        rows.append(alwaysSendLogsRow)

        return rows
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

    private func displayStoreSandboxSecretInserter() {
        let view = StoreSandboxSecretScreen(cookieJar: HTTPCookieStorage.shared)
        let viewController = UIHostingController(rootView: view)

        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func displayWeeklyRoundupDebugTools() {
        let view = WeeklyRoundupDebugScreen()
        let viewController = UIHostingController(rootView: view)

        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func enableQuickStart(for blog: Blog) {
        QuickStartTourGuide.shared.setup(for: blog)
    }

    // MARK: Reader

    private var readerRows: [ImmuTableRow] {
        return [
            EditableTextRow(title: Strings.readerCssTitle, value: ReaderCSS().customAddress ?? "") { row in
                let textViewController = SettingsTextViewController(text: ReaderCSS().customAddress, placeholder: Strings.readerURLPlaceholder, hint: Strings.readerURLHint)
                textViewController.title = Strings.readerCssTitle
                textViewController.onAttributedValueChanged = { [weak self] url in
                    var readerCSS = ReaderCSS()
                    readerCSS.customAddress = url.string
                    self?.reloadViewModel()
                }

                self.navigationController?.pushViewController(textViewController, animated: true)
            }
        ]
    }

    enum Strings {
        static let overridden = NSLocalizedString("Overridden", comment: "Used to indicate a setting is overridden in debug builds of the app")
        static let featureFlags = NSLocalizedString("Feature flags", comment: "Title of the Feature Flags screen used in debug builds of the app")
        static let tools = NSLocalizedString("Tools", comment: "Title of the Tools section of the debug screen used in debug builds of the app")
        static let sandboxStoreCookieSecretRow = NSLocalizedString("Use Sandbox Store", comment: "Title of a row displayed on the debug screen used to configure the sandbox store use in the App.")
        static let quickStartRow = NSLocalizedString("Enable Quick Start for Site", comment: "Title of a row displayed on the debug screen used in debug builds of the app")
        static let sendTestCrash = NSLocalizedString("Send Test Crash", comment: "Title of a row displayed on the debug screen used to crash the app and send a crash report to the crash logging provider to ensure everything is working correctly")
        static let sendLogMessage = NSLocalizedString("Send Log Message", comment: "Title of a row displayed on the debug screen used to send a pretend error message to the crash logging provider to ensure everything is working correctly")
        static let alwaysSendLogs = NSLocalizedString("Always Send Crash Logs", comment: "Title of a row displayed on the debug screen used to indicate whether crash logs should be forced to send, even if they otherwise wouldn't")
        static let crashLogging = NSLocalizedString("Crash Logging", comment: "Title of a section on the debug screen that shows a list of actions related to crash logging")
        static let encryptedLogging = NSLocalizedString("Encrypted Logs", comment: "Title of a row displayed on the debug screen used to display a screen that shows a list of encrypted logs")
        static let reader = NSLocalizedString("Reader", comment: "Title of the Reader section of the debug screen used in debug builds of the app")
        static let readerCssTitle = NSLocalizedString("Reader CSS URL", comment: "Title of the screen that allows the user to change the Reader CSS URL for debug builds")
        static let readerURLPlaceholder = NSLocalizedString("Default URL", comment: "Placeholder for the reader CSS URL")
        static let readerURLHint = NSLocalizedString("Add a custom CSS URL here to be loaded in Reader. If you're running Calypso locally this can be something like: http://192.168.15.23:3000/calypso/reader-mobile.css", comment: "Hint for the reader CSS URL field")
    }
}

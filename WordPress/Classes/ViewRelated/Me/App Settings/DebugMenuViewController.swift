import UIKit
import AutomatticTracks
import SwiftUI
import Pulse
import PulseUI

struct DebugMenuView: View {
    @StateObject private var viewModel = DebugMenuViewModel()

    fileprivate var navigation: NavigationContext

    var body: some View {
        List {
            Section { main }
            Section("Settings") { settings }
            Section("Quick Start") { quickStart }
            Section("Logging") { logging }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                (Text(Image(systemName: "bolt.fill")).foregroundColor(.yellow) + Text(" " + Strings.title)).font(.headline)
            }
        }
    }

    @ViewBuilder private var main: some View {
        NavigationLink {
            ConsoleView().closeButtonHidden()
        } label: {
            DebugMenuRow(systemImage: "message.fill", color: .blue, title: Strings.console)
        }

        NavigationLink {
            DebugFeatureFlagsView()
        } label: {
            DebugMenuRow(systemImage: "flag.fill", color: .pink, title: Strings.featureFlags)
        }
    }

    @ViewBuilder private var settings: some View {
        NavigationLink("Sandbox Store") {
            // TODO:
        }
        NavigationLink("Remote Config") {
            // TODO:
        }
        NavigationLink("Weekly Roundup") {
            // TODO:
        }
        NavigationLink("Reader CSS URL") {
            // TODO:
        }
    }

    @ViewBuilder private var quickStart: some View {
        Button("Enable Quick Start for New Site") {
            // TODO:
        }
        Button("Enable Quick Start for Existing Site") {
            // TODO:
        }
        Button("Stop Current Tour", role: .destructive) {
            // TODO:
        }
    }

    @ViewBuilder private var logging: some View {
        Button("Send Test Log Message") {
            WordPressAppDelegate.crashLogging?.logMessage("Debug Log Message \(UUID().uuidString)")
        }
        Button("Send Test Crash Message") {
            DDLogInfo("Initiating user-requested crash")
            WordPressAppDelegate.crashLogging?.crash()
        }
        if let eventLogging = WordPressAppDelegate.eventLogging {
            let viewController = EncryptedLogTableViewController(eventLogging: eventLogging)
            Button {
                navigation.push(viewController)
            } label: {
                HStack {
                    Text("Encrypted Logs")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }.buttonStyle(.plain)
        }
        Toggle("Always Send Crash Logs", isOn: $viewModel.isForcedCrashLoggingEnabled)
    }
}

private final class DebugMenuViewModel: ObservableObject {
    var isForcedCrashLoggingEnabled: Bool {
        get { UserSettings.userHasForcedCrashLoggingEnabled }
        set {
            UserSettings.userHasForcedCrashLoggingEnabled = newValue
            objectWillChange.send()
        }
    }
}

private struct DebugMenuRow: View {
    let systemImage: String
    let color: Color
    let title: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26, alignment: .center)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(title)
            Spacer()
        }
    }
}

final class DebugMenuViewController: UIHostingController<DebugMenuView> {
    init() {
        let navigation = NavigationContext()
        super.init(rootView: DebugMenuView(navigation: navigation))
        navigation.parentViewController = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func configure(in window: UIWindow?) {
        guard FeatureFlag.debugMenu.enabled else {
            return
        }
        assert(window != nil)

        Pulse.URLSessionProxyDelegate.enableAutomaticRegistration()

        let gesture = UIScreenEdgePanGestureRecognizer(target: DebugMenuViewController.self, action: #selector(showDebugMenu))
        gesture.edges = .right
        window?.addGestureRecognizer(gesture)
    }

    @objc private static func showDebugMenu() {
        guard let window = UIApplication.sharedIfAvailable()?.mainWindow,
              let topViewController = window.topmostPresentedViewController,
              !((topViewController as? UINavigationController)?.viewControllers.first is DebugMenuViewController) else {
            return
        }
        let viewController = DebugMenuViewController()
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { [weak topViewController] _ in
            topViewController?.dismiss(animated: true)
        })
        viewController.configureDefaultNavigationBarAppearance()

        let navigation = UINavigationController(rootViewController: viewController)
        navigation.navigationBar.isTranslucent = true // Reset to default
        topViewController.present(navigation, animated: true)
    }
}

private final class NavigationContext {
    weak var parentViewController: UIViewController?

    /// The alternative solution of using `UIViewControllerRepresentable` won't
    /// work well without a convoluted way to pass navigaiton items.
    func push(_ viewController: UIViewController) {
        parentViewController?.navigationController?.pushViewController(viewController, animated: true)
    }
}

class DebugMenuViewController2: UITableViewController {
    private var handler: ImmuTableViewHandler!

    override init(style: UITableView.Style) {
        super.init(style: style)

        title = NSLocalizedString("Debug Settings", comment: "Debug settings title")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    required convenience init() {
//        self.init(style: .insetGrouped)
//    }

//    static func configure(in window: UIWindow?) {
//        guard FeatureFlag.debugMenu.enabled else {
//            return
//        }
//        assert(window != nil)
//
//        Pulse.URLSessionProxyDelegate.enableAutomaticRegistration()
//
//        let gesture = UIScreenEdgePanGestureRecognizer(target: DebugMenuViewController.self, action: #selector(showDebugMenu))
//        gesture.edges = .right
//        window?.addGestureRecognizer(gesture)
//    }
//
//    @objc private static func showDebugMenu() {
//        guard let window = UIApplication.sharedIfAvailable()?.mainWindow,
//              let topViewController = window.topmostPresentedViewController,
//              !((topViewController as? UINavigationController)?.viewControllers.first is DebugMenuViewController) else {
//            return
//        }
//        let viewController = DebugMenuViewController()
//        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { [weak topViewController] _ in
//            topViewController?.dismiss(animated: true)
//        })
//        viewController.configureDefaultNavigationBarAppearance()
//
//        let navigation = UINavigationController(rootViewController: viewController)
//        navigation.navigationBar.isTranslucent = true // Reset to default
//        topViewController.present(navigation, animated: true)
//    }

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
        handler.viewModel = ImmuTable(sections: [
//            ImmuTableSection(headerText: Strings.general, rows: generalRows),
            ImmuTableSection(headerText: Strings.tools, rows: toolsRows),
            ImmuTableSection(headerText: Strings.crashLogging, rows: crashLoggingRows),
            ImmuTableSection(headerText: Strings.reader, rows: readerRows),
        ])
    }

    // MARK: Tools

//    private var generalRows: [ImmuTableRow] {
//        [
//            NavigationItemRow(title: Strings.featureFlags, icon: UIImage(systemName: "flag.fill")) { [weak self] _ in
//                let vc = UIHostingController(rootView: DebugFeatureFlagsView())
//                vc.title = "Feature Flags"
//                self?.navigationController?.pushViewController(vc, animated: true)
//            },
//            NavigationItemRow(title: Strings.console, icon: UIImage(systemName: "exclamationmark.bubble.fill")?.settingsIcon(background: .red)) { [weak self] _ in
//                let vc = UIHostingController(rootView: ConsoleView().closeButtonHidden())
//                vc.title = "Console"
//                self?.navigationController?.pushViewController(vc, animated: true)
//            }
//        ]
//    }

    private var toolsRows: [ImmuTableRow] {
        var toolsRows = [
            ButtonRow(title: Strings.quickStartForNewSiteRow, action: { [weak self] _ in
                self?.displayBlogPickerForQuickStart(type: .newSite)
            }),
            ButtonRow(title: Strings.quickStartForExistingSiteRow, action: { [weak self] _ in
                self?.displayBlogPickerForQuickStart(type: .existingSite)
            }),
            ButtonRow(title: Strings.removeQuickStartRow, action: { [weak self] _ in
                if let blog = RootViewCoordinator.sharedPresenter.mySitesCoordinator.currentBlog {
                    QuickStartTourGuide.shared.remove(from: blog)
                }
                self?.tableView.deselectSelectedRowWithAnimationAfterDelay(true)
            }),
            ButtonRow(title: Strings.sandboxStoreCookieSecretRow, action: { [weak self] _ in
                self?.displayStoreSandboxSecretInserter()
            }),
            ButtonRow(title: Strings.remoteConfigTitle, action: { [weak self] _ in
                self?.displayRemoteConfigDebugMenu()
            }),
        ]

        toolsRows.append(ButtonRow(title: "Weekly Roundup", action: { [weak self] _ in
            self?.displayWeeklyRoundupDebugTools()
        }))

        return toolsRows
    }

    // MARK: Crash Logging

    private var crashLoggingRows: [ImmuTableRow] {

//        var rows: [ImmuTableRow] = [
//            ButtonRow(title: Strings.sendLogMessage, action: { _ in
//                WordPressAppDelegate.crashLogging?.logMessage("Debug Log Message \(UUID().uuidString)")
//                self.tableView.deselectSelectedRowWithAnimationAfterDelay(true)
//            }),
//            ButtonRow(title: Strings.sendTestCrash, action: { _ in
//                DDLogInfo("Initiating user-requested crash")
//                WordPressAppDelegate.crashLogging?.crash()
//            })
//        ]
//
//        if let eventLogging = WordPressAppDelegate.eventLogging {
//            let tableViewController = EncryptedLogTableViewController(eventLogging: eventLogging)
//            let encryptedLoggingRow = ButtonRow(title: Strings.encryptedLogging) { _ in
//                self.navigationController?.pushViewController(tableViewController, animated: true)
//            }
//            rows.append(encryptedLoggingRow)
//        }
//
//        let alwaysSendLogsRow = SwitchWithSubtitleRow(title: Strings.alwaysSendLogs, value: UserSettings.userHasForcedCrashLoggingEnabled) { isOn in
//            UserSettings.userHasForcedCrashLoggingEnabled = isOn
//        }

//        rows.append(alwaysSendLogsRow)
//
//        return rows
        return []
    }

    private func displayBlogPickerForQuickStart(type: QuickStartType) {
        let successHandler: BlogSelectorSuccessHandler = { [weak self] selectedObjectID in
            guard let blog = ContextManager.shared.mainContext.object(with: selectedObjectID) as? Blog else {
                return
            }

            self?.dismiss(animated: true) { [weak self] in
                self?.enableQuickStart(for: blog, type: type)
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

    private func enableQuickStart(for blog: Blog, type: QuickStartType) {
        QuickStartTourGuide.shared.setup(for: blog, type: type)
    }

    private func displayRemoteConfigDebugMenu() {
        let viewController = RemoteConfigDebugViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
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
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.title", value: "Developer", comment: "Title for debug menu screen")
    static let tools = NSLocalizedString("Tools", comment: "Title of the Tools section of the debug screen used in debug builds of the app")
    static let sandboxStoreCookieSecretRow = NSLocalizedString("Use Sandbox Store", comment: "Title of a row displayed on the debug screen used to configure the sandbox store use in the App.")
    static let quickStartForNewSiteRow = NSLocalizedString("Enable Quick Start for New Site", comment: "Title of a row displayed on the debug screen used in debug builds of the app")
    static let quickStartForExistingSiteRow = NSLocalizedString("Enable Quick Start for Existing Site", comment: "Title of a row displayed on the debug screen used in debug builds of the app")
    static let sendTestCrash = NSLocalizedString("Send Test Crash", comment: "Title of a row displayed on the debug screen used to crash the app and send a crash report to the crash logging provider to ensure everything is working correctly")
    static let sendLogMessage = NSLocalizedString("Send Log Message", comment: "Title of a row displayed on the debug screen used to send a pretend error message to the crash logging provider to ensure everything is working correctly")
    static let alwaysSendLogs = NSLocalizedString("Always Send Crash Logs", comment: "Title of a row displayed on the debug screen used to indicate whether crash logs should be forced to send, even if they otherwise wouldn't")
    static let crashLogging = NSLocalizedString("Crash Logging", comment: "Title of a section on the debug screen that shows a list of actions related to crash logging")
    static let encryptedLogging = NSLocalizedString("Encrypted Logs", comment: "Title of a row displayed on the debug screen used to display a screen that shows a list of encrypted logs")
    static let reader = NSLocalizedString("Reader", comment: "Title of the Reader section of the debug screen used in debug builds of the app")
    static let readerCssTitle = NSLocalizedString("Reader CSS URL", comment: "Title of the screen that allows the user to change the Reader CSS URL for debug builds")
    static let readerURLPlaceholder = NSLocalizedString("Default URL", comment: "Placeholder for the reader CSS URL")
    static let readerURLHint = NSLocalizedString("Add a custom CSS URL here to be loaded in Reader. If you're running Calypso locally this can be something like: http://192.168.15.23:3000/calypso/reader-mobile.css", comment: "Hint for the reader CSS URL field")
    static let remoteConfigTitle = NSLocalizedString("debugMenu.remoteConfig.title", value: "Remote Config", comment: "Remote Config debug menu title")
    static let general = NSLocalizedString("debugMenu.generalSectionTitle", value: "General", comment: "General section title")
    static let featureFlags = NSLocalizedString("debugMenu.featureFlags", value: "Feature Flags", comment: "Feature flags menu item")
    static let console = NSLocalizedString("debugMenu.console", value: "Console", comment: "Networking debug menu item")
    static let removeQuickStartRow = NSLocalizedString("debugMenu.removeQuickStart", value: "Remove Current Tour", comment: "Remove current quick start tour menu item")
}


private extension UIImage {
    func settingsIcon(background: UIColor) -> UIImage {
        let targetSize = CGSize(width: 19, height: 19)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        background.setFill()
        let completeRect = CGRect(origin: .zero, size: targetSize)
        UIBezierPath(roundedRect: completeRect, cornerRadius: 4).fill()

        let originalSize = self.size
        let scale = min(targetSize.width / originalSize.width, targetSize.height / originalSize.height) * 0.8
        let imageSize = self.size.scaled(by: scale)
        let origin = CGPoint(x: (targetSize.width - imageSize.width) / 2, y: (targetSize.height - imageSize.height) / 2)
        let imageRect = CGRect(origin: origin, size: imageSize)
        withTintColor(.white).draw(in: imageRect, blendMode: .normal, alpha: 1)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

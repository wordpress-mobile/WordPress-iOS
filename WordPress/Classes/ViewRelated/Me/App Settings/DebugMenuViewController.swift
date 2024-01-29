import UIKit
import AutomatticTracks
import SwiftUI
import WordPressFlux

struct DebugMenuView: View {
    @StateObject private var viewModel = DebugMenuViewModel()

    fileprivate var navigation: NavigationContext

    var body: some View {
        List {
            Section { main }
            Section(Strings.sectionSettings) { settings }
            if let blog = viewModel.blog {
                Section(Strings.sectionQuickStart) { makeQuickStart(with: blog) }
            }
            Section(Strings.sectionLogging) { logging }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                (Text(Image(systemName: "bolt.fill")).foregroundColor(.yellow) + Text(" " + Strings.title)).font(.headline)
            }
        }
    }

    @ViewBuilder private var main: some View {
        NavigationLink {
            DebugFeatureFlagsView()
        } label: {
            DebugMenuRow(systemImage: "flag.fill", color: .pink, title: Strings.featureFlags)
        }
        NavigationLink() {
            BooleanUserDefaultsDebugView()
        } label: {
            DebugMenuRow(systemImage: "server.rack", color: .gray, title: Strings.booleanUserDefaults)
        }
    }

    @ViewBuilder private var settings: some View {
        NavigationLink(Strings.remoteConfigTitle) {
            RemoteConfigDebugView()
        }
        NavigationLink(Strings.sandboxStoreCookieSecretRow) {
            StoreSandboxSecretScreen(cookieJar: HTTPCookieStorage.shared)
        }
        NavigationLink(Strings.weeklyRoundup) {
            WeeklyRoundupDebugScreen()
        }
        NavigationLink(Strings.readerCssTitle) {
            readerSettings
        }
    }

    @ViewBuilder private func makeQuickStart(with blog: Blog) -> some View {
        Button(Strings.quickStartForNewSiteRow) {
            QuickStartTourGuide.shared.setup(for: blog, type: .newSite)
            viewModel.objectWillChange.send() // Refresh
            showSuccessNotice()
        }
        Button(Strings.quickStartForExistingSiteRow) {
            QuickStartTourGuide.shared.setup(for: blog, type: .existingSite)
            viewModel.objectWillChange.send() // Refresh
            showSuccessNotice()
        }
        Button(Strings.removeQuickStartRow, role: .destructive) {
            QuickStartTourGuide.shared.remove(from: blog)
            viewModel.objectWillChange.send() // Refresh
            showSuccessNotice()
        }.disabled(blog.quickStartType == .undefined)
    }

    @ViewBuilder private var logging: some View {
        Button(Strings.sendLogMessage) {
            WordPressAppDelegate.crashLogging?.logMessage("Debug Log Message \(UUID().uuidString)")
            showSuccessNotice()
        }
        Button(Strings.sendTestCrash) {
            DDLogInfo("Initiating user-requested crash")
            WordPressAppDelegate.crashLogging?.crash()
        }
        if let eventLogging = WordPressAppDelegate.eventLogging {
            let viewController = EncryptedLogTableViewController(eventLogging: eventLogging)
            Button {
                navigation.push(viewController)
            } label: {
                HStack {
                    Text(Strings.encryptedLogging)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
        Toggle(Strings.alwaysSendLogs, isOn: $viewModel.isForcedCrashLoggingEnabled)
    }

    private var readerSettings: some View {
        let viewController = SettingsTextViewController(text: ReaderCSS().customAddress, placeholder: Strings.readerURLPlaceholder, hint: Strings.readerURLHint)
        viewController.title = Strings.readerCssTitle
        viewController.onAttributedValueChanged = {
            var reader = ReaderCSS()
            reader.customAddress = $0.string
        }
        return Wrapped(viewController: viewController)
    }
}

private func showSuccessNotice() {
    let notice = Notice(title: "✅", feedbackType: .success)
    ActionDispatcher.dispatch(NoticeAction.post(notice))
}

private final class DebugMenuViewModel: ObservableObject {
    var blog: Blog? {
        RootViewCoordinator.sharedPresenter.mySitesCoordinator.currentBlog
    }

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

private struct Wrapped<T: UIViewController>: UIViewControllerRepresentable {
    let viewController: T

    func makeUIViewController(context: Context) -> T { viewController }
    func updateUIViewController(_ viewController: T, context: Context) {}
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.title", value: "Developer", comment: "Title for debug menu screen")
    static let sectionSettings = NSLocalizedString("debugMenu.section.settings", value: "Settings", comment: "Debug Menu section title")
    static let sectionLogging = NSLocalizedString("debugMenu.section.logging", value: "Logging", comment: "Debug Menu section title")
    static let sectionQuickStart = NSLocalizedString("debugMenu.section.quickStart", value: "Quick Start", comment: "Debug Menu section title")
    static let sandboxStoreCookieSecretRow = NSLocalizedString("Sandbox Store", comment: "Title of a row displayed on the debug screen used to configure the sandbox store use in the App.")
    static let quickStartForNewSiteRow = NSLocalizedString("Enable Quick Start for New Site", comment: "Title of a row displayed on the debug screen used in debug builds of the app")
    static let quickStartForExistingSiteRow = NSLocalizedString("Enable Quick Start for Existing Site", comment: "Title of a row displayed on the debug screen used in debug builds of the app")
    static let sendTestCrash = NSLocalizedString("Send Test Crash", comment: "Title of a row displayed on the debug screen used to crash the app and send a crash report to the crash logging provider to ensure everything is working correctly")
    static let sendLogMessage = NSLocalizedString("Send Log Message", comment: "Title of a row displayed on the debug screen used to send a pretend error message to the crash logging provider to ensure everything is working correctly")
    static let alwaysSendLogs = NSLocalizedString("Always Send Crash Logs", comment: "Title of a row displayed on the debug screen used to indicate whether crash logs should be forced to send, even if they otherwise wouldn't")
    static let encryptedLogging = NSLocalizedString("Encrypted Logs", comment: "Title of a row displayed on the debug screen used to display a screen that shows a list of encrypted logs")
    static let readerCssTitle = NSLocalizedString("debugMenu.readerCellTitle", value: "Reader CSS URL", comment: "Title of the screen that allows the user to change the Reader CSS URL for debug builds")
    static let readerURLPlaceholder = NSLocalizedString("debugMenu.readerDefaultURL", value: "Default URL", comment: "Placeholder for the reader CSS URL")
    static let readerURLHint = NSLocalizedString("debugMenu.readerHit", value: "Add a custom CSS URL here to be loaded in Reader. If you're running Calypso locally this can be something like: http://192.168.15.23:3000/calypso/reader-mobile.css", comment: "Hint for the reader CSS URL field")
    static let remoteConfigTitle = NSLocalizedString("debugMenu.remoteConfig.title", value: "Remote Config", comment: "Remote Config debug menu title")
    static let analyics = NSLocalizedString("debugMenu.analytics", value: "Analytics", comment: "Debug menu item title")
    static let featureFlags = NSLocalizedString("debugMenu.featureFlags", value: "Feature Flags", comment: "Feature flags menu item")
    static let removeQuickStartRow = NSLocalizedString("debugMenu.removeQuickStart", value: "Remove Current Tour", comment: "Remove current quick start tour menu item")
    static let weeklyRoundup = NSLocalizedString("debugMenu.weeklyRoundup", value: "Weekly Roundup", comment: "Weekly Roundup debug menu item")
    static let booleanUserDefaults = NSLocalizedString("debugMenu.booleanUserDefaults", value: "Boolean User Defaults", comment: "Boolean User Defaults debug menu item")
}

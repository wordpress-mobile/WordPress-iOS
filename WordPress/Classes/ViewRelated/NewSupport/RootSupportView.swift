import DesignSystem
import SwiftUI
import Support
import UIKit
import WordPressAPIInternal
import WordPressData
import WordPressShared
import WordPressUI
import WebKit

struct RootSupportView: View {

    enum ViewState {
        case loading
        case partiallyLoaded(user: SupportUser?)
        case loaded(user: SupportUser?)
        case error(Error)

        var isLoading: Bool {
            guard case .loading = self else {
                return false
            }

            return true
        }
    }

    @EnvironmentObject
    var dataProvider: SupportDataProvider

    /// Closes the screen. Set when the screen is presented rather than pushed, where it has no back button.
    var close: (() -> Void)?

    /// Starts logging out of WordPress.com. Set where the app's own Log Out button can't be reached.
    var logOut: (() -> Void)?

    @State
    private var state: ViewState = .loading

    @State
    private var isExtraDebugEnabled = UserPersistentStoreFactory.instance()
        .bool(forKey: RootSupportView.extraDebugKey)

    /// The saved setting that makes the app's logs more detailed. `WPLogger` reads it.
    private static let extraDebugKey = "extra_debug"

    var body: some View {
        VStack {
            switch self.state {
            case .loading:
                ProgressView(Strings.loading)
            case .partiallyLoaded(user: let currentUser), .loaded(let currentUser):
                listView(identity: currentUser)
            case .error(let error):
                EmptyStateView.failure(error: error) {
                    Task { await self.reloadIdentity() }
                }
            }
        }
        .task(self.loadIdentity)
        .refreshable(action: self.reloadIdentity)
        .navigationTitle(Strings.title)
        .toolbar {
            if let close {
                ToolbarItem(placement: .topBarLeading) {
                    Button.make(role: .close, action: close)
                }
            }
        }
    }

    @ViewBuilder
    private func listView(identity: SupportUser?) -> some View {
        List {
            if let identity {
                Section(Strings.profileHeader) {
                    ProfileView(user: identity)
                }
            } else {
                signInSection
            }

            Section(Strings.helpHeader) {
                communitySupportLink
                if let identity {
                    unifiedSupportLink(for: identity)
                }
            }

            Section(Strings.diagnosticsHeader) {
                applicationLogLink
                diagnosticsLink
                extraDebugToggle
            }

            if let logOut {
                Section(Strings.accountHeader) {
                    Button(Strings.logOut, role: .destructive, action: logOut)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// Shown in place of the profile when there's no WordPress.com identity — the support conversations need
    /// one, so offer the sign-in that unlocks them rather than leaving the user with documentation alone.
    @ViewBuilder
    private var signInSection: some View {
        Section {
            Button(action: signIn) {
                Text(Strings.signInTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
        } footer: {
            Text(Strings.signInDetail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func signIn() {
        guard let viewController = UIViewController.topViewController else {
            return wpAssertionFailure("support sign-in requires a presenting view controller")
        }

        Task { @MainActor in
            let account = await WordPressDotComAuthenticator().signIn(from: viewController, context: .support)
            guard account != nil else { return }

            // `support` leaves this screen on-screen, so pick up the new identity in place: the sign-in
            // prompt gives way to the profile, and the support conversations become reachable.
            await reloadIdentity()
        }
    }

    @ViewBuilder
    private var communitySupportLink: some View {
        NavigationLink {
            helpCenterWebView
        } label: {
            SupportAreaRow(
                imageName: "book.pages",
                title: Strings.helpCenterTitle,
                detail: Strings.helpCenterDetail
            )
        }
    }

    /// The documentation is a web page, so it gets the whole screen: it scrolls under the bars above and
    /// below it the way a browser does. Reached from the Me tab, below means the tab bar as well as the
    /// home indicator.
    private var helpCenterWebView: some View {
        WebKitView(configuration: Self.helpCenterConfiguration())
            .ignoresSafeArea(edges: [.top, .bottom])
    }

    private static func helpCenterConfiguration() -> WebViewControllerConfiguration {
        let url = URL(string: "https://apps.wordpress.com/support/mobile/")!
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.ignoresSafeArea = true
        return configuration
    }

    @ViewBuilder
    private func unifiedSupportLink(for identity: SupportUser) -> some View {
        NavigationLink {
            UnifiedSupportListView(context: .shared, currentUser: identity)
        } label: {
            SupportAreaRow(
                imageName: "questionmark.bubble",
                title: Strings.getHelpTitle,
                detail: Strings.getHelpDetail
            )
        }
    }

    @ViewBuilder
    private var applicationLogLink: some View {
        NavigationLink {
            ActivityLogListView()
                .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        } label: {
            SupportAreaRow(
                imageName: "wrench.and.screwdriver",
                title: Strings.applicationLogsTitle,
                detail: Strings.applicationLogsDetail
            )
        }
    }

    @ViewBuilder
    private var diagnosticsLink: some View {
        NavigationLink {
            DiagnosticsView()
                .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        } label: {
            SupportAreaRow(
                imageName: "doc.text.magnifyingglass",
                title: Strings.systemStatusTitle,
                detail: Strings.systemStatusDetail
            )
        }
    }

    @ViewBuilder
    private var extraDebugToggle: some View {
        Toggle(isOn: $isExtraDebugEnabled) {
            SupportAreaRow(
                imageName: "ladybug",
                title: Strings.debugTitle,
                detail: Strings.debugDetail
            )
        }
        .onChange(of: isExtraDebugEnabled) { _, isEnabled in
            UserPersistentStoreFactory.instance().set(isEnabled, forKey: Self.extraDebugKey)
            WPLogger.configureLoggerLevelWithExtraDebug()
        }
    }

    @Sendable private func loadIdentity() async {

        do {
            let result = try self.dataProvider.loadSupportIdentity()

            // Don't treat a `nil` value as a cache miss – they might not be logged into WP.com
            let cachedIdentity = try await result.cachedResult()
            self.state = .partiallyLoaded(user: cachedIdentity)

            // If we fail to fetch the user's identity, we'll assume they're logged out
            let fetchedIdentity = try? await result.fetchedResult()

            self.state = .loaded(user: fetchedIdentity)
        } catch {
            self.state = .error(error)
        }
    }

    @Sendable private func reloadIdentity() async {
        do {
            let fetchedIdentity = try await self.dataProvider.loadSupportIdentity().fetchedResult()
            self.state = .loaded(user: fetchedIdentity)
        } catch {
            self.state = .error(error)
        }
    }
}

struct SupportAreaRow: View {

    let imageName: String
    let title: String
    let detail: String

    /// Matches the icon column the Me screen's rows use, and keeps it growing with the text.
    @ScaledMetric(relativeTo: .callout)
    private var iconWidth: CGFloat = 24

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: imageName)
                .frame(width: iconWidth)
                .foregroundStyle(AppColor.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

class RootSupportViewController: UIHostingController<AnyView>, SearchableActivityConvertable {

    private let dataProvider: SupportDataProvider

    /// - Parameters:
    ///   - showsCloseButton: Adds a button that dismisses the screen. Pass `true` when presenting the screen
    ///     rather than pushing it.
    ///   - showsLogOutButton: Adds a button that logs out of WordPress.com. Pass `true` where the Me screen,
    ///     which has the app's own Log Out button, can't be reached.
    init(
        dataProvider: SupportDataProvider = .shared,
        showsCloseButton: Bool = false,
        showsLogOutButton: Bool = false
    ) {
        self.dataProvider = dataProvider
        super.init(rootView: AnyView(EmptyView()))

        let view = RootSupportView(
            close: showsCloseButton ? { [weak self] in self?.dismiss(animated: true) } : nil,
            logOut: showsLogOutButton ? { [weak self] in self?.logOut() } : nil
        )
        rootView = AnyView(view.environmentObject(dataProvider))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Presents the support screen in its own navigation stack, with a button to close it.
    static func present(from presentingViewController: UIViewController, showsLogOutButton: Bool = false) {
        let supportViewController = RootSupportViewController(
            showsCloseButton: true,
            showsLogOutButton: showsLogOutButton
        )
        let navigationController = UINavigationController(rootViewController: supportViewController)
        navigationController.modalPresentationStyle = .formSheet
        presentingViewController.present(navigationController, animated: true)
    }

    /// Presents the support screen on top of whatever the app is showing.
    static func presentFromLeafViewController() {
        guard let leafViewController = UIApplication.shared.leafViewController else {
            return wpAssertionFailure("support requires a presenting view controller")
        }
        present(from: leafViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // The loading and error states draw no list, so the hosting view's own background —
        // `.systemBackground`, i.e. white — is what fills the screen until the list arrives.
        // That is the shade the screen visibly changes from as it pushes in from Me. Match the
        // grouped background the list and every other Me screen use.
        view.backgroundColor = .systemGroupedBackground

        WPAnalytics.track(.openedSupport)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerUserActivity()
    }

    private func logOut() {
        LogOutActionHandler().logOut(with: self)
    }

    // MARK: - SearchableActivityConvertable

    // Declared here rather than in an extension: `@objc` members aren't allowed in extensions of a class
    // that inherits from a generic class.

    var activityType: String {
        WPActivityType.support.rawValue
    }

    var activityTitle: String {
        NSLocalizedString(
            "Help & Support",
            comment: "Title of the 'Help & Support' screen within the 'Me' tab - used for spotlight indexing on iOS."
        )
    }

    var activityKeywords: Set<String>? {
        let keywords = NSLocalizedString(
            "wordpress, help, support, faq, questions, debug, logs, help center, contact",
            comment:
                "This is a comma separated list of keywords used for spotlight indexing of the 'Help & Support' screen within the 'Me' tab"
        )
        .arrayOfTags()
        return keywords.isEmpty ? nil : Set(keywords)
    }
}

#Preview {
    NavigationStack {
        List {
            Section(Strings.helpHeader) {
                SupportAreaRow(
                    imageName: "questionmark.bubble",
                    title: Strings.getHelpTitle,
                    detail: Strings.getHelpDetail
                )
                SupportAreaRow(
                    imageName: "book.pages",
                    title: Strings.helpCenterTitle,
                    detail: Strings.helpCenterDetail
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Strings.title)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "support.root.title",
        value: "Support",
        comment: "Title of the support screen."
    )
    static let loading = NSLocalizedString(
        "support.root.loading",
        value: "Loading Support Profile",
        comment: "Shown while the support screen loads the signed-in user's profile."
    )
    static let profileHeader = NSLocalizedString(
        "support.root.profile.header",
        value: "Support Profile",
        comment: "Header of the section showing the signed-in user's support profile."
    )
    static let helpHeader = NSLocalizedString(
        "support.root.help.header",
        value: "How can we help?",
        comment: "Header of the section listing the ways to get help."
    )
    static let diagnosticsHeader = NSLocalizedString(
        "support.root.diagnostics.header",
        value: "Diagnostics",
        comment: "Header of the section listing the app's diagnostic tools."
    )
    static let helpCenterTitle = NSLocalizedString(
        "support.root.helpCenter.title",
        value: "Help Center",
        comment: "Title of the row that opens the mobile apps support documentation."
    )
    static let helpCenterDetail = NSLocalizedString(
        "support.root.helpCenter.detail",
        value: "Documentation and tutorials to help you get started.",
        comment: "Description of the row that opens the mobile apps support documentation."
    )
    static let getHelpTitle = NSLocalizedString(
        "support.root.getHelp.title",
        value: "Get help",
        comment: "Title of the row that opens the support conversations with the AI Assistant and support team."
    )
    static let getHelpDetail = NSLocalizedString(
        "support.root.getHelp.detail",
        value: "Get answers from our support team, anytime",
        comment: "Description of the row that opens the support conversations."
    )
    static let signInTitle = NSLocalizedString(
        "support.root.signIn.title",
        value: "Log into WordPress.com",
        comment: "Title of the button that starts WordPress.com sign-in from the support screen."
    )
    static let signInDetail = NSLocalizedString(
        "support.root.signIn.detail",
        value: "Log into WordPress.com to access support chat.",
        comment: "Explains why signing in to WordPress.com is needed to reach the support conversations."
    )
    static let applicationLogsTitle = NSLocalizedString(
        "support.root.applicationLogs.title",
        value: "Application Logs",
        comment: "Title of the row that opens the app's logs."
    )
    static let applicationLogsDetail = NSLocalizedString(
        "support.root.applicationLogs.detail",
        value: "Find out what the app is doing under the hood.",
        comment: "Description of the row that opens the app's logs."
    )
    static let systemStatusTitle = NSLocalizedString(
        "support.root.systemStatus.title",
        value: "System Status Report",
        comment: "Title of the row that opens the app's diagnostic tools."
    )
    static let systemStatusDetail = NSLocalizedString(
        "support.root.systemStatus.detail",
        value: "Tools to help diagnose issues",
        comment: "Description of the row that opens the app's diagnostic tools."
    )
    static let debugTitle = NSLocalizedString(
        "support.row.debug.title",
        value: "Debug",
        comment: "Title of the switch on the support screen that makes the app's logs more detailed."
    )
    static let debugDetail = NSLocalizedString(
        "support.root.debug.detail",
        value: "Add more detail to the logs to help troubleshoot issues.",
        comment: "Description of the switch on the support screen that makes the app's logs more detailed."
    )
    static let accountHeader = NSLocalizedString(
        "support.sectionHeader.account.title",
        value: "WordPress.com Account",
        comment: "WordPress.com sign-out section header title"
    )
    static let logOut = NSLocalizedString(
        "support.button.logOut.title",
        value: "Log Out",
        comment: "Button for confirming logging out from WordPress.com account"
    )
}

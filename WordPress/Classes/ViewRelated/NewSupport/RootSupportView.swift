import BuildSettingsKit
import DesignSystem
import SwiftUI
import Support
import WordPressAPIInternal
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

    @State
    private var state: ViewState = .loading

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
    }

    @ViewBuilder
    private func listView(identity: SupportUser?) -> some View {
        List {
            if let identity {
                Section(Strings.profileHeader) {
                    ProfileView(user: identity)
                }
            }

            Section(Strings.helpHeader) {
                communitySupportLink
                if let identity, isUnifiedSupportAvailable {
                    unifiedSupportLink(for: identity)
                } else {
                    communityForumLink
                }
            }

            Section(Strings.diagnosticsHeader) {
                applicationLogLink
                diagnosticsLink
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var communitySupportLink: some View {
        NavigationLink {
            let url = URL(string: "https://apps.wordpress.com/support/mobile/")!
            WebKitView(configuration: WebViewControllerConfiguration(url: url))
        } label: {
            SupportAreaRow(
                imageName: "book.pages",
                title: Strings.helpCenterTitle,
                detail: Strings.helpCenterDetail
            )
        }
    }

    /// The unified support flow is only available in the Jetpack app.
    private var isUnifiedSupportAvailable: Bool {
        BuildSettings.current.brand == .jetpack
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

    /// Offered wherever the unified support flow isn't — a brand with no Happiness Engineer channel, or a user
    /// we have no WP.com identity for — so nobody is left with documentation alone. It's the same place the
    /// support screen this one replaces sends them.
    @ViewBuilder
    private var communityForumLink: some View {
        NavigationLink {
            let url = URL(string: "https://wordpress.org/support/forum/mobile/")!
            WebKitView(configuration: WebViewControllerConfiguration(url: url))
        } label: {
            SupportAreaRow(
                imageName: "person.2",
                title: Strings.communityForumTitle,
                detail: Strings.communityForumDetail
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

class RootSupportViewController: UIHostingController<AnyView> {

    private let dataProvider: SupportDataProvider

    @MainActor
    init(dataProvider: SupportDataProvider) {
        self.dataProvider = dataProvider
        let type = RootSupportView().environmentObject(self.dataProvider)
        super.init(rootView: AnyView(erasing: type))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    static let communityForumTitle = NSLocalizedString(
        "support.root.communityForum.title",
        value: "Community Forums",
        comment: "Title of the row that opens the WordPress.org support forums."
    )
    static let communityForumDetail = NSLocalizedString(
        "support.root.communityForum.detail",
        value: "Ask a question and get help from our group of volunteers.",
        comment: "Description of the row that opens the WordPress.org support forums."
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
}

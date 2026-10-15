import SwiftUI
import Support
import UIKit
import WordPressAPIInternal
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

    @State
    private var state: ViewState = .loading

    var body: some View {
        VStack {
            switch self.state {
            case .loading:
                ProgressView("Loading Support Profile")
            case .partiallyLoaded(user: let currentUser), .loaded(let currentUser):
                listView(identity: currentUser)
            case .error(let error):
                ErrorView(
                    title: "Unable to load support",
                    message: error.localizedDescription
                )
            }
        }
        .task(self.loadIdentity)
        .refreshable(action: self.reloadIdentity)
        .navigationTitle("Support")
    }

    @ViewBuilder
    private func listView(identity: SupportUser?) -> some View {
        List {
            if let identity {
                Section("Support Profile") {
                    ProfileView(user: identity)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            } else {
                signInSection
            }

            Section("How can we help?") {
                communitySupportLink
                if let identity {
                    unifiedSupportLink(for: identity)
                }
            }

            Section("Diagnostics") {
                applicationLogLink
                diagnosticsLink
            }
        }
        .listStyle(.insetGrouped)
        .listRowBackground(Color(.secondarySystemGroupedBackground))
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
            let account = await WordPressDotComAuthenticator().signIn(from: viewController, context: .default)
            guard account != nil else { return }

            // Signing in rebuilds the navigation stack this screen sits on, so it's gone by the time we get
            // here. Navigate back to it, now with an identity, so the user lands where they can get help.
            RootViewCoordinator.sharedPresenter.navigateToSupport()
        }
    }

    @ViewBuilder
    private var communitySupportLink: some View {
        NavigationLink {
            let url = URL(string: "https://apps.wordpress.com/support/mobile/")!
            WebKitView(configuration: WebViewControllerConfiguration(url: url))
        } label: {
            SupportAreaRow(
                imageName: "book.pages",
                title: "Help Center",
                detail: "Documentation and tutorials to help you get started."
            )
        }
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
                title: "Application Logs",
                detail: "Find out what the app is doing under the hood."
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
                title: "System Status Report",
                detail: "Tools to help diagnose issues"
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

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: imageName)
                .frame(width: 24)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
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
//
//#Preview {
//    RootSupportView()
//}

private enum Strings {
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
}

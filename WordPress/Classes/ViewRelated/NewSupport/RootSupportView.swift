import SwiftUI
import Support
import WordPressAPIInternal
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
            }

            Section("How can we help?") {
                communitySupportLink
                if let identity {
                    botSupportLink(for: identity)
                    humanSupportLink(for: identity)
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

    @ViewBuilder
    private var communitySupportLink: some View {
        NavigationLink {
            let url = URL(string: "https://apps.wordpress.com/support/")!
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
    private func botSupportLink(for identity: SupportUser) -> some View {
        NavigationLink {
            ConversationListView(currentUser: identity)
                .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        } label: {
            SupportAreaRow(
                imageName: "bubble.left.and.text.bubble.right",
                title: "Ask the bots",
                detail: "Get quick answers to common questions."
            )
        }
    }

    @ViewBuilder
    private func humanSupportLink(for identity: SupportUser) -> some View {
        NavigationLink {
            SupportConversationListView(currentUser: identity)
                .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
        } label: {
            SupportAreaRow(
                imageName: "envelope.badge",
                title: "Ask the Happiness Engineers",
                detail: "For your tough questions. We'll reply via email."
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
        HStack(spacing: 12) {
            Image(systemName: imageName)
                .frame(width: 24, height: 24)
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

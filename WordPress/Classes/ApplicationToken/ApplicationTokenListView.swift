import SwiftUI
import DesignSystem
import WordPressUI
import WordPressAPI

struct ApplicationTokenListView: View {

    @StateObject
    private var viewModel: ApplicationTokenListViewModel

    @State private var isShowingInfo = false

    fileprivate init(tokens: [ApplicationTokenItem]) {
        let dataProvider = StaticTokenProvider(tokens: .success(tokens))
        self.init(dataProvider: dataProvider)
    }

    fileprivate init(error: Error) {
        let dataProvider = StaticTokenProvider(tokens: .failure(error))
        self.init(dataProvider: dataProvider)
    }

    init(dataProvider: ApplicationTokenListDataProvider) {
        _viewModel = .init(wrappedValue: ApplicationTokenListViewModel(dataProvider: dataProvider))
    }

    var body: some View {
        VStack {
            if viewModel.isLoadingData && viewModel.applicationTokens.isEmpty {
                ProgressView()
            } else if let error = viewModel.errorMessage, viewModel.applicationTokens.isEmpty {
                EmptyStateView(Self.errorTitle, systemImage: "exclamationmark.triangle", description: error)
            } else {
                List {
                    Section {
                        ForEach(viewModel.applicationTokens) { token in
                            ApplicationTokenListItemView(item: token, viewModel: viewModel)
                        }
                    }
                    .listSectionSeparator(.hidden, edges: .top)
                }
                .listStyle(.plain)
                .refreshable { await viewModel.fetchTokens() }
            }
        }
        .navigationTitle(Self.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingInfo) {
            NavigationStack {
                ApplicationPasswordsInfoView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: SelfHostedSiteAuthenticator.applicationPasswordUpdated)) {
            _ in
            viewModel.invalidateCurrentPassword()
            Task { await viewModel.fetchTokens() }
        }
        .onAppear {
            if viewModel.applicationTokens.isEmpty {
                Task {
                    await viewModel.fetchTokens()
                }
            }
        }
    }
}

@MainActor
class ApplicationTokenListViewModel: ObservableObject {

    @Published
    private(set) var isLoadingData: Bool = false

    @Published
    private(set) var errorMessage: String? = nil

    @Published
    private(set) var applicationTokens: [ApplicationTokenItem]

    @Published private(set) var deletingTokenID: UUID?
    @Published private(set) var credentialRevision = 0

    private var fetchRevision = 0
    let dataProvider: ApplicationTokenListDataProvider

    init(dataProvider: ApplicationTokenListDataProvider) {
        self.dataProvider = dataProvider
        self.applicationTokens = []
    }

    func fetchTokens() async {
        guard deletingTokenID == nil else { return }
        fetchRevision += 1
        let revision = fetchRevision
        isLoadingData = true
        errorMessage = nil
        defer {
            if revision == fetchRevision { isLoadingData = false }
        }

        do {
            var tokens = try await self.dataProvider.loadApplicationTokens()
                .sorted { lhs, rhs in
                    // The most recently used/created is placed at the top.
                    (lhs.lastUsed ?? .distantPast, lhs.createdAt) > (rhs.lastUsed ?? .distantPast, rhs.createdAt)
                }
            if let current = tokens.firstIndex(where: { $0.isCurrent }) {
                tokens.move(fromOffsets: IndexSet(integer: current), toOffset: 0)
            }
            guard revision == fetchRevision else { return }
            self.applicationTokens = tokens
        } catch {
            guard revision == fetchRevision else { return }
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteToken(_ token: ApplicationTokenItem) async throws -> Bool {
        guard deletingTokenID == nil else { return false }
        guard applicationTokens.contains(where: { $0.uuid == token.uuid && $0.canDelete }) else {
            throw token.deletionBlocker
        }
        deletingTokenID = token.uuid
        defer { deletingTokenID = nil }
        try await dataProvider.deleteApplicationToken(uuid: token.uuid)
        discardInFlightFetch()
        applicationTokens.removeAll { $0.uuid == token.uuid }
        return true
    }

    func invalidateCurrentPassword() {
        credentialRevision += 1
        discardInFlightFetch()
        for index in applicationTokens.indices {
            applicationTokens[index].isCurrent = false
            applicationTokens[index].canDelete = false
        }
    }

    /// Stops a fetch that is already running from overwriting newer state, such as restoring a deleted row.
    private func discardInFlightFetch() {
        fetchRevision += 1
        isLoadingData = false
    }
}

// MARK: - Localization

extension ApplicationTokenListView {
    static var title: String {
        NSLocalizedString(
            "applicationPassword.list.title",
            value: "Application Passwords",
            comment: "Title of application passwords list"
        )
    }

    static var errorTitle: String {
        NSLocalizedString("generic.error.title", value: "Error", comment: "A generic title for an error")
    }
}

// MARK: - SwiftUI Preview

class StaticTokenProvider: ApplicationTokenListDataProvider {

    private let result: Result<[ApplicationTokenItem], Error>

    init(tokens: Result<[ApplicationTokenItem], Error>) {
        self.result = tokens
    }

    func loadApplicationTokens() async throws -> [ApplicationTokenItem] {
        try result.get()
    }

    func deleteApplicationToken(uuid: UUID) async throws {}
}

#Preview {
    NavigationView {
        ApplicationTokenListView(tokens: .testTokens)
    }
}

#Preview {
    NavigationView {
        ApplicationTokenListView(
            error: WpApiError.WpError(
                errorCode: .ApplicationPasswordsDisabledForUser,
                errorMessage: "Not available for the current user",
                statusCode: 400,
                response: "{}",
                requestUrl: "http://example.com",
                requestMethod: .get
            )
        )
    }
}

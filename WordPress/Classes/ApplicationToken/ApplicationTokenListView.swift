import SwiftUI
import DesignSystem
import WordPressUI
import WordPressAPI

struct ApplicationTokenListView: View {

    @StateObject
    private var viewModel: ApplicationTokenListViewModel

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
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack {
                if viewModel.isLoadingData {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    EmptyStateView(Self.errorTitle, systemImage: "exclamationmark.triangle", description: error)
                } else {
                    List(viewModel.applicationTokens) { token in
                        ApplicationTokenListItemView(item: token)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle(Self.title)
        .navigationBarTitleDisplayMode(.inline)
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

    let dataProvider: ApplicationTokenListDataProvider

    init(dataProvider: ApplicationTokenListDataProvider) {
        self.dataProvider = dataProvider
        self.applicationTokens = []
    }

    func fetchTokens() async {
        isLoadingData = true
        defer {
            isLoadingData = false
        }

        do {
            let tokens = try await self.dataProvider.loadApplicationTokens()
                .sorted { lhs, rhs in
                    // The most recently used/created is placed at the top.
                    (lhs.lastUsed ?? .distantPast, lhs.createdAt) > (rhs.lastUsed ?? .distantPast, rhs.createdAt)
                }
            self.applicationTokens = tokens
        } catch let error as WpApiError {
            self.errorMessage = error.errorMessage
        } catch {
            self.errorMessage = SharedStrings.Error.generic
        }
    }
}

// MARK: - Localization

extension ApplicationTokenListView {
    static var title: String { NSLocalizedString("applicationPassword.list.title", value: "Application Passwords", comment: "Title of application passwords list") }

    static var errorTitle: String { NSLocalizedString("generic.error.title", value: "Error", comment: "A generic title for an error") }
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

}

#Preview {
    NavigationView {
        ApplicationTokenListView(tokens: .testTokens)
    }
}

#Preview {
    NavigationView {
        ApplicationTokenListView(error: WpApiError.WpError(errorCode: .ApplicationPasswordsDisabledForUser, errorMessage: "Not available for the current user", statusCode: 400, response: "{}"))
    }
}

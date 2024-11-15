import SwiftUI
import DesignSystem
import WordPressUI
import WordPressAPI

struct ApplicationTokenListView: View {

    @ObservedObject
    private var viewModel: ApplicationTokenListViewModel

    fileprivate init(tokens: [ApplicationTokenItem]) {
        let dataProvider = StaticTokenProvider(tokens: .success(tokens))
        self.init(viewModel: ApplicationTokenListViewModel(dataProvider: dataProvider))
    }

    fileprivate init(error: Error) {
        let dataProvider = StaticTokenProvider(tokens: .failure(error))
        self.init(viewModel: ApplicationTokenListViewModel(dataProvider: dataProvider))
    }

    init(viewModel: ApplicationTokenListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            if viewModel.isLoadingData {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                EmptyStateView(Self.errorTitle, systemImage: "exclamationmark.triangle", description: error)
            } else {
                List(viewModel.applicationTokens) { token in
                    ApplicationTokenListItemView(item: token)
                }
                .listStyle(.plain)
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

class ApplicationTokenListViewModel: ObservableObject {

    @Published
    private(set) var isLoadingData: Bool = false

    @Published
    private(set) var errorMessage: String? = nil

    @Published
    private(set) var applicationTokens: [ApplicationTokenItem]

    private let dataProvider: ApplicationTokenListDataProvider!

    init(dataProvider: ApplicationTokenListDataProvider) {
        self.dataProvider = dataProvider
        self.applicationTokens = []
    }

    @MainActor
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

private extension WpApiError {
    var errorMessage: String {
        switch self {
        case .InvalidHttpStatusCode, .SiteUrlParsingError, .UnknownError:
            return NSLocalizedString("Something went wrong", comment: "A generic error message")
        case let .RequestExecutionFailed(_, reason):
            return reason
        case .ResponseParsingError:
            return NSLocalizedString("generic.error.unparsableResponse", value: "Your site sent a response that the app could not parse", comment: "Error message when failing to parse API responses")
        case let .WpError(_, errorMessage, _, _):
            let format = NSLocalizedString("generic.error.rest-api-error", value: "Your site sent an error response: %@", comment: "Error message format when REST API returns an error response. The first argument is error message.")
            return String(format: format, errorMessage)
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

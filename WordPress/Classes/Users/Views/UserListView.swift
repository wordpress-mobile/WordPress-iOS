import SwiftUI
import WordPressUI

public struct UserListView: View {

    @StateObject
    private var viewModel: UserListViewModel
    private let currentUserId: Int32
    private let userService: UserServiceProtocol
    private let applicationTokenListDataProvider: ApplicationTokenListDataProvider

    public init(currentUserId: Int32, userService: UserServiceProtocol, applicationTokenListDataProvider: ApplicationTokenListDataProvider) {
        self.currentUserId = currentUserId
        self.userService = userService
        self.applicationTokenListDataProvider = applicationTokenListDataProvider
        _viewModel = StateObject(wrappedValue: UserListViewModel(userService: userService, currentUserId: currentUserId))
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            Group {
                if let error = viewModel.error {
                    EmptyStateView(error, systemImage: "exclamationmark.triangle.fill")
                } else {
                    List(viewModel.sortedUsers) { section in
                        Section(section.headerText) {
                            if section.users.isEmpty {
                                Text(Strings.noUsersFound)
                                    .font(.body)
                                    .foregroundStyle(Color.secondary)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(section.users) { user in
                                    UserListItem(user: user, isCurrentUser: user.id == currentUserId, userService: userService, applicationTokenListDataProvider: applicationTokenListDataProvider)
                                }
                            }
                        }
                    }
                    .searchable(text: $viewModel.searchTerm, prompt: Text(Strings.searchPrompt))
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                    .refreshable(action: viewModel.refreshItems)
                }
            }
        }
        .navigationTitle(Strings.usersListTitle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    if viewModel.isRefreshing {
                        ProgressView()
                    }
                    Text(Strings.usersListTitle)
                        .font(.headline)
                }
            }
        }
        .task(id: viewModel.mode) {
            await viewModel.performQuery()
        }
        .task { await viewModel.onAppear() }
    }

    enum Strings {
        static let searchPrompt = NSLocalizedString(
            "userlist.searchprompt",
            value: "Search",
            comment: "An instruction for the user to tap to start searching"
        )

        static let usersListTitle = NSLocalizedString(
            "userlist.title",
            value: "Users",
            comment: "The heading at the top of the user list"
        )

        static let noUsersFound = NSLocalizedString(
            "userlist.nousersfound",
            value: "No users found",
            comment: "Shown when the user list is empty"
        )
    }
}

#Preview("Loading") {
    NavigationView {
        UserListView(currentUserId: 0, userService: MockUserProvider(), applicationTokenListDataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
    }
}

#Preview("Error") {
    NavigationView {
        UserListView(currentUserId: 0, userService: MockUserProvider(scenario: .error), applicationTokenListDataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
    }
}

#Preview("List") {
    NavigationView {
        UserListView(currentUserId: 0, userService: MockUserProvider(scenario: .dummyData), applicationTokenListDataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
    }
}

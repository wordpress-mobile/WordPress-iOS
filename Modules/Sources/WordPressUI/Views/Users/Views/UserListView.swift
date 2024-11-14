import SwiftUI

public struct UserListView: View {

    @StateObject
    private var viewModel: UserListViewModel
    private let userProvider: UserDataProvider
    private let actionDispatcher: UserManagementActionDispatcher

    public init(userProvider: UserDataProvider, actionDispatcher: UserManagementActionDispatcher) {
        self.userProvider = userProvider
        self.actionDispatcher = actionDispatcher
        _viewModel = StateObject(wrappedValue: UserListViewModel(userProvider: userProvider))
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            Group {
                if let error = viewModel.error {
                    EmptyStateView(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                } else if viewModel.isLoadingItems {
                    ProgressView()
                } else {
                    List(viewModel.sortedUsers) { section in
                        Section(section.role) {
                            if section.users.isEmpty {
                                Text(Strings.noUsersFound)
                                    .font(.body)
                                    .foregroundStyle(Color.secondary)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(section.users) { user in
                                    UserListItem(user: user, userProvider: userProvider, actionDispatcher: actionDispatcher)
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
        UserListView(userProvider: MockUserProvider(scenario: .infinitLoading), actionDispatcher: UserManagementActionDispatcher())
    }
}

#Preview("Error") {
    NavigationView {
        UserListView(userProvider: MockUserProvider(scenario: .error), actionDispatcher: UserManagementActionDispatcher())
    }
}

#Preview("List") {
    NavigationView {
        UserListView(userProvider: MockUserProvider(scenario: .dummyData), actionDispatcher: UserManagementActionDispatcher())
    }
}

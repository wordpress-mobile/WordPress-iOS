import SwiftUI

public struct UserListView: View {

    @StateObject
    private var viewModel: UserListViewModel
    private let userService: UserServiceProtocol

    public init(userService: UserServiceProtocol) {
        self.userService = userService
        _viewModel = StateObject(wrappedValue: UserListViewModel(userService: userService))
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
                                    UserListItem(user: user, userService: userService)
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
        UserListView(userService: MockUserProvider())
    }
}

#Preview("Error") {
    NavigationView {
        UserListView(userService: MockUserProvider(scenario: .error))
    }
}

#Preview("List") {
    NavigationView {
        UserListView(userService: MockUserProvider(scenario: .dummyData))
    }
}

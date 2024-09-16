import SwiftUI

public struct UserListView: View {

    @StateObject
    var viewModel = UserListViewModel()

    public init() {}

    public var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyErrorView(error: error)
            } else if viewModel.isLoadingItems {
                ListLoadingView()
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
                                UserListItem(user: user)
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
        .navigationTitle(Strings.usersListTitle)
        .task { await viewModel.fetchItems() }
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

#Preview {
    NavigationView {
        UserListView()
    }
}

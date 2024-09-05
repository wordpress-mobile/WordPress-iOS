import SwiftUI

public struct UserListView: View {

    @ObservedObject
    var viewModel = UserListViewModel()

    public init() {}

    public var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .multilineTextAlignment(.center)
            } else if viewModel.isLoadingItems {
                ProgressView()
            } else {
                List(viewModel.sortedUsers) { section in
                    Section(section.role) {
                        ForEach(section.users) { user in
                            UserListItem(user: user)
                        }
                    }
                }
                .searchable(text: $viewModel.searchTerm, prompt: Text(Strings.searchPrompt))
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
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
    }
}

#Preview {
    NavigationView {
        UserListView()
    }
}

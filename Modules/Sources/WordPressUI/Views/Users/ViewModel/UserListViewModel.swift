import SwiftUI
import WordPressShared

class UserListViewModel: ObservableObject {

    struct Section: Identifiable {
        var id: String { role }
        let role: String
        let users: [DisplayUser]
    }

    /// The initial set of users fetched by `fetchItems`
    private var users: [DisplayUser] = []

    @Published
    var sortedUsers: [Section] = []

    @Published
    var error: Error? = nil

    @Published
    var isLoadingItems: Bool = true

    @Published
    var searchTerm: String = "" {
        didSet {
            if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                self.sortedUsers = sortUsers(users)
            } else {
                let searchResults = users.search(query: searchTerm)
                self.sortedUsers = [Section(role: "Search Results", users: searchResults)]
            }
        }
    }

    @MainActor
    func fetchItems() async {
        isLoadingItems = true
        defer { isLoadingItems = false }

        do {
            let users = try await UserObjectResolver.userProvider.fetchUsers()
            self.users = users
            self.sortedUsers = sortUsers(users)
        } catch let err {
            self.error = err
        }
    }

    private func sortUsers(_ users: [DisplayUser]) -> [Section] {
        Dictionary(grouping: users, by: { $0.role })
            .map { Section(role: $0.key, users: $0.value.sorted(by: { $0.username < $1.username })) }
            .sorted { $0.role < $1.role }
    }
}

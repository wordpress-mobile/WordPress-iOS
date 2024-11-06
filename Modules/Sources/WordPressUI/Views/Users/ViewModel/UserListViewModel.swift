import SwiftUI
import WordPressShared

@MainActor
class UserListViewModel: ObservableObject {

    struct Section: Identifiable {
        var id: String { role }
        let role: String
        let users: [DisplayUser]
    }

    /// The initial set of users fetched by `fetchItems`
    private var users: [DisplayUser] = []
    private let userProvider: UserDataProvider

    private var initialLoad = false

    @Published
    private(set) var sortedUsers: [Section] = []

    @Published
    private(set) var error: Error? = nil

    @Published
    private(set) var isLoadingItems: Bool = true

    @Published
    var searchTerm: String = "" {
        didSet {
            if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                setSearchResults(sortUsers(users))
            } else {
                let searchResults = users.search(searchTerm, using: \.searchString)
                setSearchResults([Section(role: "Search Results", users: searchResults)])
            }
        }
    }

    init(userProvider: UserDataProvider) {
        self.userProvider = userProvider
    }

    func onAppear() async {
        if !initialLoad {
            initialLoad = true
            await fetchItems()
        }
    }

    func fetchItems() async {
        withAnimation {
            isLoadingItems = true
        }

        do {
            let users = try await userProvider.fetchUsers { cachedResults in
                self.setUsers(cachedResults)
            }
            setUsers(users)
        } catch {
            self.error = error
            isLoadingItems = false
        }
    }

    @Sendable
    func refreshItems() async {
        do {
            let users = try await userProvider.fetchUsers { cachedResults in
                self.setUsers(cachedResults)
            }
            setUsers(users)
        } catch {
            // Do nothing for now – this should probably show a "Toast" notification or something
        }
    }

    func setUsers(_ newValue: [DisplayUser]) {
        withAnimation {
            self.users = newValue
            self.sortedUsers = sortUsers(newValue)
            isLoadingItems = false
        }
    }

    func setSearchResults(_ newValue: [Section]) {
        withAnimation {
            self.sortedUsers = newValue
        }
    }

    private func sortUsers(_ users: [DisplayUser]) -> [Section] {
        Dictionary(grouping: users, by: { $0.role })
            .map { Section(role: $0.key, users: $0.value.sorted(by: { $0.username < $1.username })) }
            .sorted { $0.role < $1.role }
    }
}

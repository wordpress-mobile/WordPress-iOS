import SwiftUI
import Combine
import WordPressShared

@MainActor
class UserListViewModel: ObservableObject {

    struct Section: Identifiable {
        var id: String { role }
        let role: String
        let users: [DisplayUser]
    }

    /// The initial set of users fetched by `fetchItems`
    private var users: [DisplayUser] = [] {
        didSet {
            sortedUsers = self.sortUsers(users)
        }
    }
    private var updateUsersTask: Task<Void, Never>?
    private let userService: UserServiceProtocol
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

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    deinit {
        updateUsersTask?.cancel()
    }

    func onAppear() async {
        if updateUsersTask == nil {
            updateUsersTask = Task { @MainActor [weak self, usersUpdates = userService.usersUpdates] in
                for await users in usersUpdates {
                    guard let self else { break }

                    self.users = users
                }
            }
        }

        if !initialLoad {
            initialLoad = true
            await fetchItems()
        }
    }

    private func fetchItems() async {
        isLoadingItems = true
        defer { isLoadingItems = false }

        _ = try? await userService.fetchUsers()
    }

    @Sendable
    func refreshItems() async {
        _ = try? await userService.fetchUsers()
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

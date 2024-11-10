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
    private let userService: UserServiceProtocol
    private var cancellables: Set<AnyCancellable> = []
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

        userService.users
            .compactMap { try? $0.get() }
            .sink { [weak self] in
                self?.users = $0
            }
            .store(in: &cancellables)
    }

    func onAppear() async {
        if !initialLoad {
            initialLoad = true
            await fetchItems()
        }
    }

    func fetchItems() async {
        isLoadingItems = true
        userService.fetchUsers()
        userService.users.first().map { _ in false }.assign(to: &$isLoadingItems)
    }

    @Sendable
    func refreshItems() async {
        userService.fetchUsers()
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

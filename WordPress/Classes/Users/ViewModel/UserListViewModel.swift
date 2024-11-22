import SwiftUI
import Combine
import WordPressShared

@MainActor
class UserListViewModel: ObservableObject {

    enum RoleSection: Hashable, Comparable {
        case me
        case role(String)
        case searchResult

        /// Order in the users list.
        static func < (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            // The current user section and the search result section always at the top.
            case (.me, _), (.searchResult, _):
                return true
            case (_, .me), (_, .searchResult):
                return false

            case let (.role(lhs), .role(rhs)):
                return lhs < rhs
            }
        }
    }

    struct Section: Identifiable {
        var id: RoleSection
        let users: [DisplayUser]

        var headerText: String {
            switch id {
            case .me:
                return ""
            case let .role(role):
                return role
            case .searchResult:
                return NSLocalizedString("userList.searchResults.header", value: "Search Results", comment: "Header text fo the search results section in the users list")
            }
        }
    }

    /// The initial set of users fetched by `fetchItems`
    private var users: [DisplayUser] = [] {
        didSet {
            sortedUsers = self.sortUsers(users)
        }
    }
    private var updateUsersTask: Task<Void, Never>?
    private let userService: UserServiceProtocol
    private let currentUserId: Int32
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
                setSearchResults([Section(id: .searchResult, users: searchResults)])
            }
        }
    }

    init(userService: UserServiceProtocol, currentUserId: Int32) {
        self.userService = userService
        self.currentUserId = currentUserId
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
        Dictionary(grouping: users) { $0.id == currentUserId ? RoleSection.me : RoleSection.role($0.role) }
            .map { Section(id: $0.key, users: $0.value.sorted(by: { $0.username < $1.username })) }
            .sorted { $0.id < $1.id }
    }
}

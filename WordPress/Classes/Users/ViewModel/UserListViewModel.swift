import SwiftUI
import Combine
import WordPressShared
import WordPressAPI
import WordPressCore

@MainActor
class UserListViewModel: ObservableObject {

    enum Mode: Equatable {
        case allUsers
        case search(String)
    }

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

    private let userService: UserServiceProtocol
    private let currentUserId: Int32
    private var initialLoad = false

    @Published
    private(set) var mode: Mode = .allUsers

    @Published
    private(set) var sortedUsers: [Section] = []

    @Published
    private(set) var error: String? = nil

    @Published
    var searchTerm: String = "" {
        didSet {
            let keyword = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            self.mode = keyword.isEmpty ? .allUsers : .search(keyword)
        }
    }

    @Published
    var isRefreshing: Bool = false
    private var refreshItemsTask: Task<Void, Never>?

    init(userService: UserServiceProtocol, currentUserId: Int32) {
        self.userService = userService
        self.currentUserId = currentUserId
    }

    deinit {
        refreshItemsTask?.cancel()
    }

    func onAppear() async {
        if !initialLoad {
            initialLoad = true
            await refreshItems()
        }
    }

    func performQuery() async {
        let usersUpdates: AsyncStream<Result<[DisplayUser], Error>>
        switch mode {
        case .allUsers:
            usersUpdates = await userService.streamAll()
        case let .search(keyword):
            usersUpdates = await userService.streamSearchResult(input: keyword)
        }

        for await users in usersUpdates {
            switch users {
            case let .success(users):
                self.sortedUsers = self.sortUsers(users)
            case let .failure(error):
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }
    }

    @Sendable
    func refreshItems() async {
        refreshItemsTask?.cancel()
        refreshItemsTask = Task {
            isRefreshing = true
            defer { isRefreshing = false }
            do {
                try await userService.fetchUsers()
            } catch {
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }

        _ = await refreshItemsTask?.value
    }

    private func sortUsers(_ users: [DisplayUser]) -> [Section] {
        Dictionary(grouping: users) { $0.id == currentUserId ? RoleSection.me : RoleSection.role($0.role) }
            .map { Section(id: $0.key, users: $0.value.sorted(by: { $0.username < $1.username })) }
            .sorted { $0.id < $1.id }
    }
}

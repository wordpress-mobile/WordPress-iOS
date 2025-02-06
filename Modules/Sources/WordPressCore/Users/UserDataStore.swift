import Foundation
import WordPressShared

public typealias UserDataStoreQuery = InMemoryDataStore<DisplayUser>.Query
public typealias InMemoryUserDataStore = InMemoryDataStore<DisplayUser>

extension UserDataStoreQuery {
    public static var all: UserDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.username)) { _ in true }
    }

    public static func id(_ id: T.ID) -> UserDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.username)) { $0.id == id }
    }

    public static func search(_ keyword: String) -> UserDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.username)) { user in
            let theKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if theKeyword.isEmpty {
                return true
            } else {
                let search = StringRankedSearch(searchTerm: keyword)
                let score = search.score(for: user.searchString)
                guard score > 0.7 else { return false }
                return true
            }
        }
    }
}

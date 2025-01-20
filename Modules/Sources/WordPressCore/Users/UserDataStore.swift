import Foundation
@preconcurrency import Combine
import WordPressShared

public protocol UserDataStore: DataStore where T == DisplayUser, Query == UserDataStoreQuery {
}

public enum UserDataStoreQuery: Equatable, Sendable {
    case all
    case id(Set<DisplayUser.ID>)
    case search(String)
}

public actor InMemoryUserDataStore: UserDataStore, InMemoryDataStore {
    public typealias T = DisplayUser

    public var storage: [T.ID: T] = [:]
    public let updates: PassthroughSubject<Set<T.ID>, Never> = .init()

    deinit {
        updates.send(completion: .finished)
    }

    public init() {}

    public func list(query: Query) throws -> [T] {
        switch query {
        case .all:
            return Array(storage.values)
        case let .id(ids):
            return storage.reduce(into: []) {
                if ids.contains($1.key) {
                    $0.append($1.value)
                }
            }
        case let .search(keyword):
            let theKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if theKeyword.isEmpty {
                return Array(storage.values)
            } else {
                return storage.values.search(theKeyword, using: \.searchString)
            }
        }
    }
}

import Foundation
import Security
import SFHFKeychainUtils
import Testing
@testable import WordPressShared

/// Parent suite that serializes every keychain suite against the others.
/// They all share `KeychainStub`'s class-level state, and `.serialized` on
/// an individual suite only orders the tests inside it; without a common
/// serialized ancestor, separate suites still run in parallel and race on
/// the stub.
@Suite(.serialized) enum KeychainStubSuites {}

/// In-memory SFHFKeychainUtils replacement keyed by access group.
/// Class-level state: any suite using it must nest in `KeychainStubSuites`.
final class KeychainStub: SFHFKeychainUtils {
    /// group -> service -> username -> password.
    /// nil access groups are stored under `defaultGroup`.
    nonisolated(unsafe) static var groups: [String: [String: [String: String]]] = [:]
    nonisolated(unsafe) static var storeError: Error?
    nonisolated(unsafe) static var deleteError: Error?
    nonisolated(unsafe) static var readErrors: [String: Error] = [:]
    nonisolated(unsafe) static var deleteErrors: [String: Error] = [:]

    static let defaultGroup = "<default>"

    enum StubError: Error {
        case notFound
    }

    static func reset() {
        groups = [:]
        storeError = nil
        deleteError = nil
        readErrors = [:]
        deleteErrors = [:]
    }

    static func seed(group: String, service: String, username: String, password: String) {
        groups[group, default: [:]][service, default: [:]][username] = password
    }

    static func password(group: String, service: String, username: String) -> String? {
        groups[group]?[service]?[username]
    }

    override class func getPasswordForUsername(
        _ username: String!,
        andServiceName serviceName: String!,
        accessGroup: String!
    ) throws -> String {
        let group = accessGroup ?? defaultGroup
        if let error = readErrors[group] { throw error }
        guard let value = groups[group]?[serviceName]?[username] else {
            throw StubError.notFound
        }
        return value
    }

    override class func storeUsername(
        _ username: String!,
        andPassword password: String!,
        forServiceName serviceName: String!,
        accessGroup: String!,
        updateExisting: Bool
    ) throws {
        if let storeError { throw storeError }
        groups[accessGroup ?? defaultGroup, default: [:]][serviceName, default: [:]][username] = password
    }

    override class func deleteItem(
        forUsername username: String!,
        andServiceName serviceName: String!,
        accessGroup: String!
    ) throws {
        let group = accessGroup ?? defaultGroup
        if let error = deleteErrors[group] { throw error }
        if let deleteError { throw deleteError }
        guard groups[group]?[serviceName]?[username] != nil else {
            throw NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecItemNotFound))
        }
        groups[group]?[serviceName]?[username] = nil
    }
}

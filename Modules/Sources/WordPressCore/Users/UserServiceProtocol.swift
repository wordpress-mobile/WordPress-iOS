import Foundation
import WordPressAPI

public protocol UserServiceProtocol: Actor {
    func fetchUsers() async throws

    func isCurrentUserCapableOf(_ capability: String) async -> Bool

    func setNewPassword(id: UserId, newPassword: String) async throws

    func deleteUser(id: UserId, reassigningPostsTo newUserId: UserId) async throws

    func allUsers() async throws -> [DisplayUser]

    func streamSearchResult(input: String) async -> AsyncStream<Result<[DisplayUser], Error>>

    func streamAll() async -> AsyncStream<Result<[DisplayUser], Error>>
}

import Foundation
import Combine

public protocol UserServiceProtocol {
    var users: AnyPublisher<Result<[DisplayUser], Error>, Never> { get }

    func fetchUsers()

    func isCurrentUserCapableOf(_ capability: String) async throws -> Bool

    func setNewPassword(id: Int32, newPassword: String) async throws

    func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws
}

package class MockUserProvider: UserServiceProtocol {

    enum Scenario {
        case infinitLoading
        case dummyData
        case error
    }

    var scenario: Scenario

    private let subject: CurrentValueSubject<Result<[WordPressUI.DisplayUser], any Error>, Never> = .init(.success([]))

    package var users: AnyPublisher<Result<[WordPressUI.DisplayUser], any Error>, Never> {
        subject.dropFirst().eraseToAnyPublisher()
    }

    init(scenario: Scenario = .dummyData) {
        self.scenario = scenario
    }

    package func fetchUsers() {
        switch scenario {
        case .infinitLoading:
            // Do nothing
            break
        case .dummyData:
            Task {
                let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!
                do {
                    let response = try await URLSession.shared.data(from: dummyDataUrl)
                    let users = try JSONDecoder().decode([DisplayUser].self, from: response.0)
                    subject.send(.success(users))
                } catch {
                    subject.send(.failure(error))
                }
            }
        case .error:
            subject.send(.failure(URLError(.timedOut)))
        }
    }

    package func isCurrentUserCapableOf(_ capability: String) async throws -> Bool {
        true
    }

    package func setNewPassword(id: Int32, newPassword: String) async throws {
        // Not used in Preview
    }

    package func deleteUser(id: Int32, reassigningPostsTo newUserId: Int32) async throws {
        // Not used in Preview
    }
}

import Foundation

public protocol UserProvider {
    func fetchUsers() async throws -> [DisplayUser]
}

package struct MockUserProvider: UserProvider {
    let dummyDataUrl = URL(string: "https://my.api.mockaroo.com/users.json?key=067c9730")!

    package func fetchUsers() async throws -> [DisplayUser] {
        let response = try await URLSession.shared.data(from: dummyDataUrl)
        return try JSONDecoder().decode([DisplayUser].self, from: response.0)
    }
}

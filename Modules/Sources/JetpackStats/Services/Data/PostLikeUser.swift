import Foundation

struct PostLikesData: Equatable, Sendable {
    let users: [PostLikeUser]
    let totalCount: Int

    init(users: [PostLikeUser], totalCount: Int) {
        self.users = users
        self.totalCount = totalCount
    }

    struct PostLikeUser: Equatable, Identifiable, Sendable {
        let id: Int
        let name: String
        let avatarURL: URL?

        init(id: Int, name: String, avatarURL: URL? = nil) {
            self.id = id
            self.name = name
            self.avatarURL = avatarURL
        }
    }

    static let mock = PostLikesData(users: [
        PostLikeUser(id: 0, name: "Alex Chen"),
        PostLikeUser(id: 1, name: "Maya Rodriguez"),
        PostLikeUser(id: 2, name: "James Wilson"),
        PostLikeUser(id: 3, name: "Zara Okafor"),
        PostLikeUser(id: 4, name: "Liam O'Connor"),
        PostLikeUser(id: 5, name: "Priya Patel"),
        PostLikeUser(id: 6, name: "Noah Kim"),
        PostLikeUser(id: 7, name: "Sofia Andersson"),
        PostLikeUser(id: 8, name: "Marcus Thompson"),
        PostLikeUser(id: 9, name: "Fatima Al-Zahra"),
        PostLikeUser(id: 10, name: "Diego Santos"),
        PostLikeUser(id: 11, name: "Emma Johansson")
    ], totalCount: 12)
}

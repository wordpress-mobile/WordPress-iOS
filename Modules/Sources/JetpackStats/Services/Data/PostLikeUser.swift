import Foundation

public struct PostLikeUser: Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let avatarURL: URL?
    
    public init(id: Int, name: String, avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
    }
}

public struct PostLikes: Equatable, Sendable {
    public let users: [PostLikeUser]
    public let totalCount: Int
    
    public init(users: [PostLikeUser], totalCount: Int) {
        self.users = users
        self.totalCount = totalCount
    }
}

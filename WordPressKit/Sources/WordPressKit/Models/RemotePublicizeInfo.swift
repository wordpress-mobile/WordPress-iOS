import Foundation

public struct RemotePublicizeInfo: Decodable {
    public let shareLimit: Int
    public let toBePublicizedCount: Int
    public let sharedPostsCount: Int
    public let sharesRemaining: Int

    private enum CodingKeys: CodingKey {
        case shareLimit
        case toBePublicizedCount
        case sharedPostsCount
        case sharesRemaining
    }
}

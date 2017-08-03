import Foundation

public class RemoteGravatarProfile {
    public let profileID: String
    public let hash: String
    public let requestHash: String
    public let profileUrl: String
    public let preferredUsername: String
    public let thumbnailUrl: String
    public let name: String
    public let displayName: String

    init(dictionary: NSDictionary) {
        profileID = dictionary.string(forKey: "id") ?? ""
        hash = dictionary.string(forKey: "hash") ?? ""
        requestHash = dictionary.string(forKey: "requestHash") ?? ""
        profileUrl = dictionary.string(forKey: "profileUrl") ?? ""
        preferredUsername = dictionary.string(forKey: "preferredUsername") ?? ""
        thumbnailUrl = dictionary.string(forKey: "thumbnailUrl") ?? ""
        name = dictionary.string(forKey: "name") ?? ""
        displayName = dictionary.string(forKey: "displayName") ?? ""
    }
}

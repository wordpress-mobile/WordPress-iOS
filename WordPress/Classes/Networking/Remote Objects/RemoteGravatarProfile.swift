import Foundation

open class RemoteGravatarProfile {
    let profileID: String
    let hash: String
    let requestHash: String
    let profileUrl: String
    let preferredUsername: String
    let thumbnailUrl: String
    let name: String
    let displayName: String

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

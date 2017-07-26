import Foundation

public class RemoteProfile {
    public let bio: String
    public let displayName: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let nicename: String
    public let nickname: String
    public let url: String
    public let userID: Int
    public let username: String


    public init(dictionary: NSDictionary) {
        bio = dictionary.string(forKey: "bio") ?? ""
        displayName = dictionary.string(forKey: "display_name") ?? ""
        email = dictionary.string(forKey: "email") ?? ""
        firstName = dictionary.string(forKey: "first_name") ?? ""
        lastName = dictionary.string(forKey: "last_name") ?? ""
        nicename = dictionary.string(forKey: "nicename") ?? ""
        nickname = dictionary.string(forKey: "nickname") ?? ""
        url = dictionary.string(forKey: "url") ?? ""
        userID = dictionary.number(forKey: "user_id")?.intValue ?? 0
        username = dictionary.string(forKey: "username") ?? ""
    }

}

import Foundation

open class RemoteProfile {
    let bio: String
    let displayName: String
    let email: String
    let firstName: String
    let lastName: String
    let nicename: String
    let nickname: String
    let url: String
    let userID: Int
    let username: String


    init(dictionary: NSDictionary) {
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

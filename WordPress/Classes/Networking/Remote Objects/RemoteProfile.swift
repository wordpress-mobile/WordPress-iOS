import Foundation

open class RemoteProfile {
    var bio = ""
    var displayName = ""
    var email = ""
    var firstName = ""
    var lastName = ""
    var nicename = ""
    var nickname = ""
    var url = ""
    var userID = 0
    var username = ""


    convenience init(dictionary: NSDictionary) {
        self.init()

        bio = dictionary.string(forKey: "bio") ?? ""
        displayName = dictionary.string(forKey: "display_name") ?? ""
        email = dictionary.string(forKey: "email") ?? ""
        firstName = dictionary.string(forKey: "first_name") ?? ""
        lastName = dictionary.string(forKey: "last_name") ?? ""
        nicename = dictionary.string(forKey: "nicename") ?? ""
        nickname = dictionary.string(forKey: "nickname") ?? ""
        url = dictionary.string(forKey: "url") ?? ""
        userID = dictionary.number(forKey: "user_id").intValue
        username = dictionary.string(forKey: "username") ?? ""
    }

}

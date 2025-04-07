import Foundation

@objcMembers public class Suggestion: NSObject {
    let userLogin: String?
    let displayName: String?
    let imageURL: URL?

    init?(dictionary: [String: Any]) {

        let userLogin = dictionary["user_login"] as? String
        let displayName = dictionary["display_name"] as? String

        // A user suggestion is only valid when at least one of these is present.
        guard userLogin != nil || displayName != nil else {
            return nil
        }

        self.userLogin = userLogin
        self.displayName = displayName

        if let imageURLString = dictionary["image_URL"] as? String {
            imageURL = URL(string: imageURLString)
        } else {
            imageURL = nil
        }
    }
}

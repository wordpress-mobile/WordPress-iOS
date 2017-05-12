import Foundation

open class RemoteGravatarProfile {
    var profileID = ""
    var hash = ""
    var requestHash = ""
    var profileUrl = ""
    var preferredUsername = ""
    var thumbnailUrl = ""
    var name = ""
    var displayName = ""

    convenience init(dict: [String: Any]) {
        self.init()

        profileID = dict.valueAsString(forKey: "id") ?? ""
        hash = dict.valueAsString(forKey: "hash") ?? ""
        requestHash = dict.valueAsString(forKey: "requestHash") ?? ""
        profileUrl = dict.valueAsString(forKey: "profileUrl") ?? ""
        preferredUsername = dict.valueAsString(forKey: "preferredUsername") ?? ""
        thumbnailUrl = dict.valueAsString(forKey: "thumbnailUrl") ?? ""
        name = dict.valueAsString(forKey: "name") ?? ""
        displayName = dict.valueAsString(forKey: "displayName") ?? ""
    }
}

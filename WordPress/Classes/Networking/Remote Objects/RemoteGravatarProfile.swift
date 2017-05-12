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

    convenience init(dict: [String: String]) {
        self.init()

        profileID = dict["id"] ?? ""
        hash = dict["hash"] ?? ""
        requestHash = dict["requestHash"] ?? ""
        profileUrl = dict["profileUrl"] ?? ""
        preferredUsername = dict["preferredUsername"] ?? ""
        thumbnailUrl = dict["thumbnailUrl"] ?? ""
        name = dict["name"] ?? ""
        displayName = dict["displayName"] ?? ""
    }
}

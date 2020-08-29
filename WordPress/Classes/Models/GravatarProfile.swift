import Foundation
import WordPressKit

public struct GravatarProfile {

    var profileID = ""
    var hash = ""
    var requestHash = ""
    var profileUrl = ""
    var preferredUsername = ""
    var thumbnailUrl = ""
    var name = ""
    var displayName = ""
    var formattedName = ""
    var aboutMe = ""
    var currentLocation = ""
    var urls: [RemoteGravatarProfileUrl] = []
}

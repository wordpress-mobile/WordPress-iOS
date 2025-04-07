public struct GravatarProfile {

    public var profileID: String
    public var hash: String
    public var requestHash: String
    public var profileUrl: String
    public var preferredUsername: String
    public var thumbnailUrl: String
    public var name: String
    public var displayName: String

    public init(
        profileID: String = "",
        hash: String = "",
        requestHash: String = "",
        profileUrl: String = "",
        preferredUsername: String = "",
        thumbnailUrl: String = "",
        name: String = "",
        displayName: String = ""
    ) {
        self.profileID = profileID
        self.hash = hash
        self.requestHash = requestHash
        self.profileUrl = profileUrl
        self.preferredUsername = preferredUsername
        self.thumbnailUrl = thumbnailUrl
        self.name = name
        self.displayName = displayName
    }
}

public struct UserProfile {
    public var bio: String
    public var displayName: String
    public var email: String
    public var firstName: String
    public var lastName: String
    public var nicename: String
    public var nickname: String
    public var url: String
    public var userID: Int
    public var username: String

    public init(
        bio: String = "",
        displayName: String = "",
        email: String = "",
        firstName: String = "",
        lastName: String = "",
        nicename: String = "",
        nickname: String = "",
        url: String = "",
        userID: Int = 0,
        username: String = ""
    ) {
        self.bio = bio
        self.displayName = displayName
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.nicename = nicename
        self.nickname = nickname
        self.url = url
        self.userID = userID
        self.username = username
    }
}

import Foundation
import WordPressShared

public struct DisplayUser: Identifiable, Codable {
    public let id: Int32
    public let handle: String
    public let username: String
    public let firstName: String
    public let lastName: String
    public let displayName: String
    public let profilePhotoUrl: URL?
    public let role: String

    public let emailAddress: String
    public let websiteUrl: String?

    public let biography: String?

    public init(
        id: Int32,
        handle: String,
        username: String,
        firstName: String,
        lastName: String,
        displayName: String,
        profilePhotoUrl: URL?,
        role: String,
        emailAddress: String,
        websiteUrl: String?,
        biography: String?
    ) {
        self.id = id
        self.handle = handle
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.profilePhotoUrl = profilePhotoUrl
        self.role = role
        self.emailAddress = emailAddress
        self.websiteUrl = websiteUrl
        self.biography = biography
    }

    static package let MockUser = DisplayUser(
        id: 16,
        handle: "@person",
        username: "example",
        firstName: "John",
        lastName: "Smith",
        displayName: "John Smith",
        profilePhotoUrl: URL(string: "https://gravatar.com/avatar/58fc51586c9a1f9895ac70e3ca60886e?size=256"),
        role: "administrator",
        emailAddress: "john@example.com",
        websiteUrl: "",
        biography: ""
    )
}

extension DisplayUser: StringRankedSearchable {
    public var searchString: String {

        // These are in ranked order – the higher something is in the list, the more heavily it's weighted
        [
            handle,
            username,
            firstName,
            lastName,
            emailAddress,
            displayName,
            emailAddress,
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

import Foundation
import WordPressShared

public struct DisplayUser: Identifiable, Codable {
    public let id: Int
    let handle: String
    let username: String
    let firstName: String
    let lastName: String
    let displayName: String
    let profilePhotoUrl: URL
    let role: String

    let emailAddress: String
    let websiteUrl: String?

    let biography: String?

    static package let MockUser = DisplayUser(
        id: 16,
        handle: "@person",
        username: "example",
        firstName: "John",
        lastName: "Smith",
        displayName: "John Smith",
        profilePhotoUrl: URL(string: "https://gravatar.com/avatar/58fc51586c9a1f9895ac70e3ca60886e?size=256")!,
        role: "administrator",
        emailAddress: "john@example.com",
        websiteUrl: "",
        biography: ""
    )
}

extension DisplayUser: StringRankedSearchable {
    public var searchString: String {
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

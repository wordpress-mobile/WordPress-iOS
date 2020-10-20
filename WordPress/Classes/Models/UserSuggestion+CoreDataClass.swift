import Foundation
import CoreData

@objc(UserSuggestion)
public class UserSuggestion: NSManagedObject, Decodable, Comparable {

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case imageURL = "image_URL"
        case username = "user_login"
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderError.missingManagedObjectContext
        }

        self.init(context: managedObjectContext)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.imageURL = try container.decode(URL.self, forKey: .imageURL)
        self.username = try container.decode(String.self, forKey: .username)
    }

    public static func < (lhs: UserSuggestion, rhs: UserSuggestion) -> Bool {
        return (lhs.displayName ?? "").localizedCaseInsensitiveCompare(rhs.displayName ?? "") == .orderedAscending
    }
}

public class UserSuggestionsPayload: Decodable {

    let suggestions: [UserSuggestion]

    enum CodingKeys: String, CodingKey {
        case suggestions = "suggestions"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let allSuggestions = try container.decode([UserSuggestion].self, forKey: .suggestions)
        suggestions = allSuggestions.filter { suggestion in
            // A user suggestion is only valid when at least one of these is present.
            suggestion.displayName != nil || suggestion.username != nil
        }
    }
}

import Foundation
import CoreData

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

enum DecoderError: Error {
    case missingManagedObjectContext
}

@objc(SiteSuggestion)
public class SiteSuggestion: NSManagedObject, Decodable {
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case siteURL = "siteurl"
        case subdomain = "subdomain"
        case blavatarURL = "blavatar"
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderError.missingManagedObjectContext
        }

        self.init(context: managedObjectContext)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.siteURL = try? container.decode(URL.self, forKey: .siteURL)
        self.subdomain = try container.decode(String.self, forKey: .subdomain)
        self.blavatarURL = try? container.decode(URL.self, forKey: .blavatarURL)
    }
}

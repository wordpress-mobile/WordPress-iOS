import Foundation
import CoreData

@objc(UserSuggestion)
public class UserSuggestion: NSManagedObject {

    convenience init?(dictionary: [String: Any], context: NSManagedObjectContext) {
        let userLoginValue = dictionary["user_login"] as? String
        let displayNameValue = dictionary["display_name"] as? String

        // A user suggestion is only valid when it has an ID and at least user_login or display_name is present.
        guard let id = dictionary["ID"] as? UInt, userLoginValue != nil || displayNameValue != nil else {
            return nil
        }

        guard let entityDescription = NSEntityDescription.entity(forEntityName: "UserSuggestion", in: context) else {
            return nil
        }
        self.init(entity: entityDescription, insertInto: context)

        self.id = NSNumber(value: id)
        self.username = userLoginValue
        self.displayName = displayNameValue

        if let imageURLString = dictionary["image_URL"] as? String {
            imageURL = URL(string: imageURLString)
        } else {
            imageURL = nil
        }
    }

}

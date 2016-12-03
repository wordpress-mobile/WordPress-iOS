import Foundation

@objc class AccountSelectionItem: NSObject {
    let userId: NSNumber
    let username: String
    let email: String

    init(userId: NSNumber, username: String, email: String) {
        self.userId = userId
        self.username = username
        self.email = email
    }

    override func isEqual(object: AnyObject?) -> Bool {
        guard let parsedObject = object as? AccountSelectionItem  else { return false}
        if self === parsedObject {
            return true
        }

        return self.username == parsedObject.username &&
            self.userId == parsedObject.userId &&
            self.email == parsedObject.email
    }
}

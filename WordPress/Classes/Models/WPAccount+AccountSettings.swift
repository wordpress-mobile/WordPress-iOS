import Foundation

extension WPAccount {
    enum VerificationStatus: String {
        case unknown
        case verified
        case unverified
    }

    func applyChange(_ change: AccountSettingsChange) {
        switch change {
        case .displayName(let value):
            self.displayName = value
        case .primarySite(let value):
            let service = BlogService(managedObjectContext: managedObjectContext!)
            defaultBlog = service.blog(byBlogId: NSNumber(value: value))
        default:
            break
        }
    }

    var verificationStatus: VerificationStatus {
        guard let verified = emailVerified?.boolValue else {
            return .unknown
        }
        return verified ? .verified : .unverified
    }

    var logDescription: String {
        let coreDataID = objectID.uriRepresentation().absoluteString
        return "<Account username: \(username ?? "-") ID: \(userID?.stringValue ?? "-"), Email: \(verificationStatus.rawValue) ObjectID: \(coreDataID)>"
    }

    var needsEmailVerification: Bool {
        return verificationStatus == .unverified
    }
}

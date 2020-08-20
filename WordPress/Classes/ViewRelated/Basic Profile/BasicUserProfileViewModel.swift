import Foundation

final class BasicUserProfileViewModel {
    let email: String?
    let avatarURL: URL?
    let emailHash: String

    init?(email: String?, avatarURL: URL?) {
        if let email = email, (email as NSString).isValidEmail() {
            emailHash = (email as NSString).md5()
            self.email = email
            self.avatarURL = nil
        } else if let avatarURL = avatarURL {
            emailHash = avatarURL.lastPathComponent
            self.email = nil
            self.avatarURL = avatarURL
        } else {
            return nil
        }
    }

    func fetchUserDetails(completion: @escaping (GravatarProfile?) -> Void) {
        let service = GravatarService()
        service.fetchProfile(hash: emailHash, onCompletion: completion)
    }
}
